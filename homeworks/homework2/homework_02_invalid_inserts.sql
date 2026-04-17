-- =============================================================================
-- INVALID DATA — DO NOT EXPECT ANY OF THESE ROWS TO BE INSERTED
-- =============================================================================
-- This script is for testing Part 1 constraints. After your `cafeteria_menu_item`
-- table is defined with all required constraints, run this against your database.
--
-- Expected outcome: EVERY INSERT below should FAIL (constraint violation).
-- If any INSERT succeeds, your constraints are incomplete or too loose.
--
-- Your instructor will use similar attempts when grading: bad values must be
-- rejected at insert time.
-- =============================================================================

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-001', 'Duplicate code on purpose', NULL, 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-999', NULL, 'X', 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-998', 'No category', NULL, NULL, 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-997', 'Bad spice', NULL, 'Test', 'Test', 99,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-996', 'Negative price', NULL, 'Test', 'Test', 2,
    -1.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-995', 'Bad station', NULL, 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'kitchen'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-994', 'Bad station 2', NULL, 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-TOOLONG'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-993', 'Negative remakes', NULL, 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    FALSE, -1, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-992', 'Missing menu date', NULL, 'Test', 'Test', 2,
    5.00, NULL, '2025-01-20 10:00:00+00', NULL,
    FALSE, 0, 'K-ALFA'
);

INSERT INTO cafeteria_menu_item (
    code, dish_name, short_label, category, kitchen_section, spice_level,
    price_eur, added_to_menu, last_restocked_at, dietary_note,
    is_late_night, remake_count, prep_station_code
) VALUES (
    'FD-991', 'Late night unknown', NULL, 'Test', 'Test', 2,
    5.00, '2025-01-01', '2025-01-20 10:00:00+00', NULL,
    NULL, 0, 'K-ALFA'
);
