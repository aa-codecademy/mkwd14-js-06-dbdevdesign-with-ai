# Homework 01 - Music Library Database Design

## Goal

Design a small database for a music streaming app where users can save favorite songs and playlists.

## Requirements

Create a SQL script that defines a database model with at least **3 tables**.

Your model must include:

- A table for **artists**
- A table for **songs**
- A table for **playlists**
- No relations between tables (no foreign keys, no join tables)

## What to include in your tables

For each table, include columns that make sense from a real-world perspective, such as:

- unique id
- name/title
- short/long text fields
- numbers (for example duration, play count, follower count)
- date or date-time values (for example release date, created at)
- status/flag values (for example explicit content yes/no, public/private playlist)

Use only these constraints:

- `PRIMARY KEY`
- `NULL` / `NOT NULL`

Do not use any other constraints (no `UNIQUE`, no foreign keys, no `CHECK`, no `DEFAULT`).

## Example: what data each table should contain

Use this only as inspiration for column ideas:

- **artists**: id, name, country, birth date, monthly listeners, is she/he active
- **songs**: id, title, artist name, genre, duration in seconds, release date, is it explicit
- **playlists**: id, name, description, owner name, followers count, created date, is it public

## Minimum data to insert

In the same SQL script, insert sample data:

- at least **5 artists**
- at least **10 songs**
- at least **3 playlists**
- at least **5 records** in each table

## Deliverables

Create one SQL script file named:

- `homework_01.sql`

The script should include:

- `CREATE TABLE` statements
- only `PRIMARY KEY` and `NULL/NOT NULL` constraints
- `INSERT` statements with sample data

## Submission Guidelines

1. Create a **new GitHub repository** for this homework.
2. Add your SQL script (`homework_01.sql`) to the repository.
3. Commit and push your solution.
4. Send the repository link by email to [ivo@kostovski.dev](mailto:ivo@kostovski.dev).
5. If your repository is private, add GitHub collaborator: `**ivokostovski`**.

