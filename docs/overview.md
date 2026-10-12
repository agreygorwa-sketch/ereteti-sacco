# Ereteti SACCO — Overview

## What this project is

A management system for a savings and credit cooperative (SACCO):

- **Members** — registration, profiles, next-of-kin, status.
- **Savings & shares** — deposits, withdrawals, share capital ledger.
- **Loans** — application, appraisal/guarantors, approval, disbursement,
  repayment schedules.
- **Reporting** — statements, arrears, dividends, admin dashboard.

## Decisions to record here

- Application stack (web / mobile / API) and why.
- Data store and hosting.
- Money handling: mobile money integration (e.g. M-Pesa), reconciliation.
- Roles and permissions (member, staff, admin, auditor).

## Conventions

- Application code lives in `src/`, tests in `tests/`.
- Keep this folder updated when a decision is made — future you will thank
  present you.
