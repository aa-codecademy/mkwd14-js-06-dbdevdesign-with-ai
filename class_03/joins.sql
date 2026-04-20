-- R001. For a featured actor, list every film they have appeared in and whether they had the lead role.

SELECT m.title, ma.is_lead_role
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
WHERE a.full_name = 'Ryan Gosling'

