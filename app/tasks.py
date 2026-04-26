import uuid
from datetime import datetime, timezone
from sqlalchemy import select, text
from app.database import AsyncSessionLocal
from app.models import User, RSVP
from app.ollama import embed, chat
from app.ranking import apply_diversity, compute_score
from app.config import settings


async def generalize_and_embed(user_id: uuid.UUID) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            return

        blob = (
            f"Name: {user.name}\n"
            f"Bio: {user.bio or ''}\n"
            f"Interests: {', '.join(user.interests or [])}\n"
            f"Hobbies: {user.hobbies or ''}\n"
            f"Projects: {user.projects or ''}\n"
            f"Skills: {', '.join(user.skills or [])}\n"
            f"Want to learn: {user.want_to_learn or ''}"
        )

        system = (
            "You are a profile normalizer. Given a raw user profile, produce a clean, "
            "concise, embedding-ready summary. Collapse redundant concepts. "
            "Output plain text only, 3-5 sentences max."
        )
        summary = await chat(system, blob)
        vector = await embed(summary)

        user.generalized_summary = summary
        user.embedding = vector
        user.updated_at = datetime.now(timezone.utc)
        await db.commit()


def _vec_str(v) -> str:
    return "[" + ",".join(f"{x:.8f}" for x in v) + "]"


async def run_matching(user_id: uuid.UUID, event_id: uuid.UUID) -> None:
    async with AsyncSessionLocal() as db:
        u_result = await db.execute(select(User).where(User.id == user_id))
        user = u_result.scalar_one_or_none()
        if not user or user.embedding is None:
            return

        emb_str = _vec_str(user.embedding)

        rows = await db.execute(
            text("""
                SELECT r.user_id,
                       u.generalized_summary,
                       u.skills,
                       1 - (u.embedding <=> :emb::vector) AS profile_sim
                FROM rsvps r
                JOIN users u ON r.user_id = u.id
                WHERE r.event_id = :event_id
                  AND r.user_id != :user_id
                  AND u.embedding IS NOT NULL
                ORDER BY profile_sim DESC
            """),
            {"emb": emb_str, "event_id": str(event_id), "user_id": str(user_id)},
        )
        candidates_raw = rows.fetchall()

        rsvp_result = await db.execute(
            select(RSVP).where(RSVP.user_id == user_id, RSVP.event_id == event_id)
        )
        current_rsvp = rsvp_result.scalar_one_or_none()

        intent_sims: dict = {}
        if current_rsvp and current_rsvp.intent_embedding is not None:
            intent_emb_str = _vec_str(current_rsvp.intent_embedding)
            intent_rows = await db.execute(
                text("""
                    SELECT r.user_id,
                           1 - (r.intent_embedding <=> :emb::vector) AS intent_sim
                    FROM rsvps r
                    WHERE r.event_id = :event_id
                      AND r.user_id != :user_id
                      AND r.intent_embedding IS NOT NULL
                """),
                {"emb": intent_emb_str, "event_id": str(event_id), "user_id": str(user_id)},
            )
            intent_sims = {row.user_id: row.intent_sim for row in intent_rows}

        scored = [
            (
                row.user_id,
                compute_score(row.profile_sim, intent_sims.get(row.user_id)),
                list(row.skills or []),
                row.generalized_summary or "",
            )
            for row in candidates_raw
        ]
        scored.sort(key=lambda x: x[1], reverse=True)
        diverse = apply_diversity(scored, settings.MAX_MATCHES)

        for matched_uid, score, _, matched_summary in diverse:
            icebreaker = await chat(
                system="",
                user_msg=(
                    "Write a single friendly icebreaker sentence (max 20 words) "
                    "for two attendees based on their shared interests. Do not use quotes.\n\n"
                    f"Person A: {user.generalized_summary}\n"
                    f"Person B: {matched_summary}"
                ),
            )
            await db.execute(
                text("""
                    INSERT INTO matches (id, user_id, event_id, matched_user_id, score, icebreaker_text, created_at)
                    VALUES (:id, :user_id, :event_id, :matched_user_id, :score, :icebreaker, :now)
                    ON CONFLICT (user_id, event_id, matched_user_id)
                    DO UPDATE SET score = EXCLUDED.score, icebreaker_text = EXCLUDED.icebreaker_text
                """),
                {
                    "id": str(uuid.uuid4()),
                    "user_id": str(user_id),
                    "event_id": str(event_id),
                    "matched_user_id": str(matched_uid),
                    "score": score,
                    "icebreaker": icebreaker,
                    "now": datetime.now(timezone.utc).isoformat(),
                },
            )
        await db.commit()
