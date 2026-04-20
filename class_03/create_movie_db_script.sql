CREATE TABLE director (
	director_id SERIAL PRIMARY KEY,
	full_name VARCHAR(100) NOT NULL,
	country VARCHAR(80),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movie (
	movie_id SERIAL PRIMARY KEY,
	director_id INTEGER NOT NULL REFERENCES director(director_id) ON DELETE RESTRICT,
	title VARCHAR(120) NOT NULL,
	release_year INTEGER NOT NULL CHECK (release_year >= 1900 AND release_year <= 2100),
	duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
	age_rating VARCHAR(10) NOT NULL CHECK (age_rating IN ('G', 'PG', 'PG-13', 'R', '18+')),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movie_detail (
	movie_id INTEGER PRIMARY KEY REFERENCES movie(movie_id) ON DELETE CASCADE,
	synopsis TEXT NOT NULL,
	tagline VARCHAR(200) NULL
);

CREATE TABLE screening (
	screning_id SERIAL PRIMARY KEY,
	movie_id INTEGER NOT NULL REFERENCES movie(movie_id) ON DELETE CASCADE,
	starts_at TIMESTAMP NOT NULL,
	hall_name VARCHAR(40) NOT NULL,
	total_seats INTEGER NOT NULL CHECK (total_seats > 0),
	available_seats INTEGER NOT NULL CHECK (available_seats >= 0),
	screening_status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
		CHECK (screening_status IN ('scheduled', 'sold_out', 'finished', 'canceled')),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CHECK (available_seats <= total_seats)
);

CREATE TABLE ticket_booking (
	ticket_booking_id SERIAL PRIMARY KEY,
	screening_id INTEGER NOT NULL REFERENCES screening(screening_id) ON DELETE CASCADE,
	customer_name VARCHAR(100) NOT NULL,
	customer_email VARCHAR(255),
	seat_count INTEGER NOT NULL CHECK (seat_count > 0),
	booking_status VARCHAR(20) NOT NULL DEFAULT 'confirmed'
		CHECK (booking_status IN ('confirmed', 'canceled')),
	booked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE genre (
	genre_id SERIAL PRIMARY KEY,
	name VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE movie_genre (
	movie_id INTEGER NOT NULL REFERENCES movie(movie_id) ON DELETE CASCADE,
	genre_id INTEGER NOT NULL REFERENCES genre(genre_id) ON DELETE CASCADE,
	PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE actor (
	actor_id SERIAL PRIMARY KEY,
	full_name VARCHAR(100) NOT NULL,
	birth_year INTEGER CHECK (birth_year >= 1850 AND birth_year <= 2100),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movie_actor (
	movie_id INTEGER NOT NULL REFERENCES movie(movie_id) ON DELETE CASCADE,
	actor_id INTEGER NOT NULL REFERENCES actor(actor_id) ON DELETE CASCADE,
	role_name VARCHAR(100),
	is_lead_role BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY (movie_id, actor_id)
);
