# Diversity — Debit Card & Expense Tracker

A web application built with **Ruby on Rails 8** that helps you track money loaded onto a debit card, the taxes deducted from salary top-ups, and how each expense was funded. Designed for the Romanian fiscal context (CAS, CASS, Impozit pe Venit, CAM).

---

## What This App Does

You load money onto a prepaid/debit card from different sources (salary, bank transfer, etc.). This app answers the question: **"What did each euro/lei actually cost me, and which funds paid for which expense?"**

### Key Concepts

| Concept | What it means |
|---|---|
| **Card Top-Up** | A sum of money loaded onto the card. Can come from a salary (gross → net) or a direct transfer. |
| **Source Deduction** | Taxes or fees taken out of a top-up before the net amount lands on the card (CAS, CASS, IV, CAM). |
| **Expense** | Money spent from the card — a purchase, bill, subscription, etc. |
| **Expense Allocation** | The link between an expense and the top-up(s) it was paid from. One expense can span multiple top-ups. |

### How It Works Together

```
Salary (gross)
  └─► Card Top-Up  ──► Source Deductions (taxes)
                   ──► Net balance available on card
                             └─► Expense Allocation ──► Expense
```

When you add an expense, the app **automatically allocates** it to available top-ups, prioritising the ones with the highest cost ratio (i.e. the most "expensive" money goes first).

---

## Technology Stack

| Layer | Technology | Role |
|---|---|---|
| **Backend framework** | [Ruby on Rails 8.1](https://rubyonrails.org/) | Handles routing, models, controllers, views |
| **Language** | Ruby 3.x | Server-side programming language |
| **Database** | SQLite 3 | Stores all data in a single file — no separate DB server needed |
| **Web server** | Puma | Runs the Rails app and serves HTTP requests |
| **Frontend** | Hotwire (Turbo + Stimulus) | Makes pages feel fast without writing much JavaScript |
| **Asset pipeline** | Propshaft + Import Maps | Serves CSS and JS without a Node.js build step |
| **Background jobs** | Solid Queue | Runs async tasks (stored in SQLite) |
| **Caching** | Solid Cache | Caches responses (stored in SQLite) |
| **Deployment** | Kamal + Docker | Packages and ships the app to a server |

> **No Node.js required.** The frontend is served via Rails import maps, so you do not need `npm` or `yarn` to run the app locally.

---

## Prerequisites

Before you start, make sure the following are installed on your machine:

### 1. Ruby

Rails 8.1 requires **Ruby 3.2 or newer**.

Check if Ruby is installed:
```bash
ruby --version
# Expected output: ruby 3.2.x or higher
```

If not installed, use [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://rvm.io/):
```bash
# With rbenv:
rbenv install 3.2.2
rbenv global 3.2.2
```

### 2. Bundler (Ruby package manager)

```bash
gem install bundler
```

### 3. SQLite 3 (system library)

On Ubuntu/Debian:
```bash
sudo apt-get install sqlite3 libsqlite3-dev
```

On macOS (with Homebrew):
```bash
brew install sqlite
```

### 4. Git

```bash
git --version
```

---

## Installation

### Step 1 — Clone the repository

```bash
git clone <repository-url>
cd diversity
```

### Step 2 — Install Ruby gems (dependencies)

This reads the `Gemfile` and installs everything the app needs:

```bash
bundle install
```

> The `Gemfile` lists all the libraries ("gems") the app depends on. `bundle install` downloads and installs them all at the versions pinned in `Gemfile.lock`.

### Step 3 — Set up the database

This creates the SQLite database file and runs all migrations (creates the tables):

```bash
bin/rails db:prepare
```

What this does internally:
- Creates `storage/development.sqlite3` (and separate files for cache/queue/cable)
- Runs all migration files in `db/migrate/` in order — each migration creates or modifies a table

### Step 4 — Start the server

```bash
bin/rails server
```

The app will be available at: **http://localhost:3000**

To stop the server, press `Ctrl + C`.

---

## Database Schema

The app uses four tables:

### `card_top_ups`
Records each time money is loaded onto the card.

| Column | Type | Description |
|---|---|---|
| `date` | date | When the top-up happened |
| `gross_amount` | decimal | Amount before deductions (e.g. gross salary) |
| `net_amount` | decimal | Amount actually received on card |
| `source_type` | string | `salary`, `transfer`, or `other` |
| `eur_rate` | decimal | EUR exchange rate at time of top-up |
| `notes` | text | Optional notes |

### `source_deductions`
Each row is one type of tax/fee deducted from a top-up.

| Column | Type | Description |
|---|---|---|
| `card_top_up_id` | integer | Which top-up this belongs to |
| `name` | string | Tax name: `CAS`, `CASS`, `IV`, `CAM`, etc. |
| `amount` | decimal | Amount deducted |

### `expenses`
Records a purchase or payment made from the card.

| Column | Type | Description |
|---|---|---|
| `date` | date | Date of the expense |
| `description` | string | What you paid for |
| `amount` | decimal | How much was spent |
| `category` | string | Optional category label |

### `expense_allocations`
Links an expense to the top-up(s) that funded it. One expense can be split across multiple top-ups.

| Column | Type | Description |
|---|---|---|
| `expense_id` | integer | Which expense |
| `card_top_up_id` | integer | Which top-up |
| `amount` | decimal | Portion of the expense funded by this top-up |

---

## How the Code Is Organised

Rails follows the **MVC pattern** — Models, Views, Controllers. Here's what each piece does in this app:

### Models (`app/models/`)

Models represent data and contain business logic.

| File | What it does |
|---|---|
| `card_top_up.rb` | Knows about deductions, calculates cost ratio, remaining balance |
| `expense.rb` | On creation, auto-allocates itself to available top-ups |
| `expense_allocation.rb` | The link between an expense and a top-up |
| `source_deduction.rb` | A single line-item deduction (one tax) on a top-up |
| `concerns/salary_calculator.rb` | Module with Romanian salary tax formulas (CAS 25%, CASS 10%, IV 10%, CAM 2.25%) |

### Controllers (`app/controllers/`)

Controllers receive HTTP requests and decide what to show or save.

| File | What it handles |
|---|---|
| `card_top_ups_controller.rb` | Create, view, edit, delete top-ups. Also a `salary_preview` JSON endpoint used by the form to show tax calculations live. |
| `expenses_controller.rb` | Create, view, edit, delete expenses. |

### Views (`app/views/`)

Views are HTML templates that display data to the user.

| Folder | What it contains |
|---|---|
| `card_top_ups/` | List of top-ups, top-up detail, create/edit forms |
| `expenses/` | List of expenses, expense detail, create/edit forms |
| `layouts/` | The shared page wrapper (header, footer, `<html>` structure) |

---

## Daily Usage

### Adding a Salary Top-Up

1. Go to **http://localhost:3000**
2. Click **New Top-Up**
3. Select source type **Salary**
4. Enter the gross salary amount — the app will show a live preview of the net amount after Romanian taxes
5. Add individual deduction lines (CAS, CASS, IV, CAM) with their amounts
6. Save

### Adding a Direct Transfer

Same as above but select **Transfer** — no tax deductions needed, gross = net.

### Adding an Expense

1. Click **New Expense**
2. Enter the date, description, amount, and optional category
3. Save — the app automatically allocates this expense to available top-up balance

### Viewing the Dashboard

The home page (`/`) shows:
- Total loaded onto the card
- Total spent
- Remaining balance
- All top-ups with their cost ratios

---

## Useful Rails Commands

```bash
# Start the development server
bin/rails server

# Open an interactive console with full access to models
bin/rails console

# List all defined routes
bin/rails routes

# Run database migrations (after pulling new changes)
bin/rails db:migrate

# Reset the database (WARNING: deletes all data)
bin/rails db:reset

# Run tests
bin/rails test

# Check for security vulnerabilities in gems
bundle exec bundler-audit

# Run the Ruby linter
bundle exec rubocop
```

---

## Running Tests

```bash
bin/rails test
```

Tests live in the `test/` folder. The app uses Rails' built-in Minitest framework together with Capybara and Selenium for browser-based system tests.

---

## Project Structure at a Glance

```
diversity/
├── app/
│   ├── controllers/     # Handle HTTP requests
│   ├── models/          # Data + business logic
│   └── views/           # HTML templates
├── config/
│   ├── routes.rb        # URL → controller mapping
│   └── database.yml     # Database connection settings
├── db/
│   ├── migrate/         # One file per schema change
│   ├── schema.rb        # Current database structure (auto-generated)
│   └── seeds.rb         # Optional starter data
├── storage/             # SQLite .sqlite3 database files live here
├── Gemfile              # Ruby dependencies
└── Gemfile.lock         # Locked dependency versions
```

---

## Common Problems

**`bundle install` fails with SQLite errors**
→ Install the system SQLite library: `sudo apt-get install libsqlite3-dev` (Linux) or `brew install sqlite` (macOS)

**`bin/rails server` says port 3000 is in use**
→ Start on a different port: `bin/rails server -p 3001`

**Database errors after pulling new code**
→ Run migrations: `bin/rails db:migrate`

**Want to start fresh with an empty database**
→ `bin/rails db:reset` (this drops and recreates all tables — all data is lost)
