#!/usr/bin/env python3
import os
import sys
import json
from claude_opus import call_claude_opus

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def run_audit():
    providers_summary = ""
    for p in ["auth_provider.dart", "tender_provider.dart", "auction_provider.dart", "bid_provider.dart", "admin_provider.dart"]:
        full_path = f"lib/providers/{p}"
        if os.path.exists(full_path):
            providers_summary += f"\n--- {p} ---\n" + read_file(full_path)

    screens_summary = ""
    for s in [
        "auth/login_screen.dart",
        "user/user_home_screen.dart",
        "user/create_tender_screen.dart",
        "transporter/transporter_home_screen.dart",
        "transporter/stage2_live_screen.dart",
        "transporter/bid_result_screen.dart",
        "transporter/place_bid_screen.dart",
        "transporter/tender_detail_transporter_screen.dart"
    ]:
        full_path = f"lib/screens/{s}"
        if os.path.exists(full_path):
            screens_summary += f"\n--- {s} ---\n" + read_file(full_path)[:1500] + "\n...[truncated for brevity]...\n"

    prompt = f"""
You are an expert Flutter enterprise architect and UI designer reviewing the LOGIQ B2B Reverse Auction application.
Google Stitch design system requirements:
- Deep Navy #0F172A, Electric Blue #2563EB, Emerald Green #059669, Cool Slate #64748B, Slate Faint #F8FAFC, #E2E8F0 borders.
- Zero bright yellow.
- Strict Provider state management: Screen -> Provider -> Service -> Local/Remote.
- Transport workers domain: Big buttons, clear visual feedback, minimal reading, smooth reactive state updates.

PROVIDERS CODE:
{providers_summary}

SCREENS CODE EXCERPTS:
{screens_summary}

Conduct an exhaustive audit:
1. State Management Flaws / Gaps:
   - Identify where state is not synchronized, where providers lack necessary methods, where reactive rebuilds are suboptimal, or where state mutation could cause race conditions or memory leaks.
2. UI / UX Flaws vs Google Stitch:
   - Identify any missing enterprise visual polish, chip styling, unhandled empty/loading states, or navigation inconsistencies across the audited screens.
3. Concrete Recommendations & File-by-File Action List:
   - Specify exactly what lines or methods to add/modify in which files.

Be thorough, hyper-critical, and precise.
"""

    print("Sending code to Claude Opus 4.6 for comprehensive audit...")
    response = call_claude_opus(prompt, "You are a principal Flutter architect conducting a code review.")
    with open("claude_audit_report.md", "w", encoding="utf-8") as out:
        out.write(response)
    print("Audit report written to claude_audit_report.md")
    print(response[:1000])

if __name__ == "__main__":
    run_audit()
