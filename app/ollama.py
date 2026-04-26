import asyncio
from functools import partial
from sentence_transformers import SentenceTransformer
from mlx_lm import load, generate
from app.config import settings

_embed_model = SentenceTransformer(settings.EMBED_MODEL)
_chat_model, _chat_tokenizer = load(settings.GENERALIZE_MODEL)


async def embed(text: str) -> list[float]:
    loop = asyncio.get_event_loop()
    vector = await loop.run_in_executor(None, partial(_embed_model.encode, text))
    return vector.tolist()


async def chat(system: str, user_msg: str) -> str:
    if system:
        prompt = f"<start_of_turn>system\n{system}<end_of_turn>\n<start_of_turn>user\n{user_msg}<end_of_turn>\n<start_of_turn>model\n"
    else:
        prompt = f"<start_of_turn>user\n{user_msg}<end_of_turn>\n<start_of_turn>model\n"

    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(
        None,
        partial(generate, _chat_model, _chat_tokenizer, prompt=prompt, max_tokens=512, verbose=False),
    )
    return response.strip()
