from app.ranking import compute_score, apply_diversity, apply_field_mask

def test_score_without_intent():
    assert compute_score(0.8, None) == 0.8

def test_score_with_intent():
    result = compute_score(0.8, 0.6)
    assert abs(result - (0.6 * 0.8 + 0.4 * 0.6)) < 1e-9

def test_diversity_deduplicates_by_top_skill():
    candidates = [
        ("u1", 0.9, ["Python", "ML"], "summary1"),
        ("u2", 0.85, ["Python", "Django"], "summary2"),  # same top skill
        ("u3", 0.8, ["Go", "gRPC"], "summary3"),
    ]
    result = apply_diversity(candidates, max_matches=4)
    ids = [r[0] for r in result]
    assert "u1" in ids
    assert "u2" not in ids  # deduplicated
    assert "u3" in ids

def test_diversity_respects_max():
    candidates = [(f"u{i}", 1.0 - i * 0.1, [f"skill{i}"], f"s{i}") for i in range(10)]
    result = apply_diversity(candidates, max_matches=4)
    assert len(result) == 4

def test_diversity_no_skills():
    candidates = [("u1", 0.9, [], "s1"), ("u2", 0.8, [], "s2")]
    result = apply_diversity(candidates, max_matches=4)
    assert len(result) == 1  # both map to "none" cluster

def test_field_mask_name_only():
    masked = apply_field_mask(
        name="Alice", photo_url="pic.jpg", bio="hello",
        interests=["ML"], skills=["Python"],
        opted_in_fields=["name"],
    )
    assert masked["name"] == "Alice"
    assert masked["photo_url"] is None
    assert masked["bio"] is None

def test_field_mask_all_fields():
    masked = apply_field_mask(
        name="Alice", photo_url="pic.jpg", bio="hello",
        interests=["ML"], skills=["Python"],
        opted_in_fields=["name", "photo", "bio", "interests", "skills"],
    )
    assert masked["name"] == "Alice"
    assert masked["photo_url"] == "pic.jpg"
    assert masked["interests"] == ["ML"]
