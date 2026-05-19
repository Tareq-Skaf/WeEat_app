import secrets


def make_4_digit_tag() -> str:
    # 0000 -> 9999
    return f"{secrets.randbelow(10000):04d}"