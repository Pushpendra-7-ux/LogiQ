from datetime import datetime


def format_currency(amount: float) -> str:
    return f"₹{amount:,.0f}"


def get_greeting() -> str:
    hour = datetime.now().hour

    if hour < 12:
        return "Good Morning"
    elif hour < 17:
        return "Good Afternoon"
    else:
        return "Good Evening"