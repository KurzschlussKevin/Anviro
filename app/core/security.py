from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
MAX_BCRYPT_LENGTH = 72  # bcrypt Limit in Bytes


def _truncate_password(password: str) -> str:
    encoded = password.encode("utf-8")
    if len(encoded) > MAX_BCRYPT_LENGTH:
        encoded = encoded[:MAX_BCRYPT_LENGTH]
        return encoded.decode("utf-8", errors="ignore")
    return password


def hash_password(password: str) -> str:
    password = _truncate_password(password)
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    plain_password = _truncate_password(plain_password)
    return pwd_context.verify(plain_password, hashed_password)
