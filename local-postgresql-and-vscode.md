# Local PostgreSQL And VS Code Setup

## Required Tools

- PostgreSQL latest stable version
- VS Code
- a free VS Code PostgreSQL extension
- Node.js

## Recommended VS Code Extension

Recommended default:

- `SQLTools`
- `SQLTools PostgreSQL/Cockroach Driver`

Why this is a good default:

- free
- works directly inside VS Code
- enough for queries, browsing, and connection management
- keeps students in the same editor they already use for JavaScript

## Local PostgreSQL Install

### Windows

- Install PostgreSQL from the official installer
- Create a local password you can easily reuse in class demos

### macOS

- Install PostgreSQL with Homebrew or Postgres.app
- Make sure PostgreSQL is running locally

### Linux

- Install PostgreSQL through the package manager
- Confirm the PostgreSQL service is running

## First Local Setup

After installation:

1. confirm PostgreSQL is running
2. create a development database such as `moviedb_db`
3. open VS Code
4. install the database extension
5. connect with:

- host: `localhost`
- port: `5432`
- database: `moviedb_db`
- username: local PostgreSQL username
- password: local PostgreSQL password

## Troubleshooting Checklist

- PostgreSQL service is not running
- wrong username or password
- wrong database name
- wrong port
- extension installed but driver missing
- local PostgreSQL tools or service are not installed correctly
