def compute_score(profile_sim: float, intent_sim: float | None) -> float:
    if intent_sim is not None:
        return 0.6 * profile_sim + 0.4 * intent_sim
    return profile_sim

def apply_diversity(
    candidates: list[tuple],  # (user_id, score, skills, summary)
    max_matches: int,
) -> list[tuple]:
    seen: set[str] = set()
    result = []
    for item in candidates:
        _, _, skills, _ = item
        top_skill = skills[0] if skills else "none"
        if top_skill not in seen:
            seen.add(top_skill)
            result.append(item)
        if len(result) >= max_matches:
            break
    return result

def apply_field_mask(
    *,
    name: str | None,
    photo_url: str | None,
    bio: str | None,
    interests: list[str] | None,
    skills: list[str] | None,
    opted_in_fields: list[str],
) -> dict:
    return {
        "name": name if "name" in opted_in_fields else None,
        "photo_url": photo_url if "photo" in opted_in_fields else None,
        "bio": bio if "bio" in opted_in_fields else None,
        "interests": interests if "interests" in opted_in_fields else None,
        "skills": skills if "skills" in opted_in_fields else None,
    }
