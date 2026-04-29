const API = '/api';

const GENRES = [
	'Drama',
	'Comedy',
	'Sci-Fi',
	'Action',
	'Adventure',
	'Thriller',
	'Romance',
	'Horror',
	'Documentary',
	'Animation',
	'Crime',
	'Musical',
	'Fantasy',
	'Western',
	'Neo-noir',
	'Biography',
	'War',
	'Family',
	'Mystery',
	'Superhero',
	'Satire',
	'Coming-of-age',
	'Sports',
	'Epic',
	'Cyberpunk',
	'Slice of Life',
	'Mockumentary',
	'Espionage',
	'Disaster',
	'Psychological',
];

const screeningsCache = new Map();
let searchDebounce;

function hueFromId(id) {
	return ((Number(id) * 47) % 360) + 30;
}

function showToast(message, type = 'success') {
	const container = document.getElementById('toast-container');
	if (!container) return;
	const toast = document.createElement('div');
	toast.className = `toast toast-${type}`;
	toast.setAttribute('role', type === 'error' ? 'alert' : 'status');
	toast.textContent = message;
	container.appendChild(toast);
	requestAnimationFrame(() => toast.classList.add('toast-visible'));
	const remove = () => {
		toast.classList.remove('toast-visible');
		toast.addEventListener('transitionend', () => toast.remove(), {
			once: true,
		});
	};
	setTimeout(remove, 3500);
	toast.addEventListener('click', remove);
}

function escapeHtml(s) {
	if (s == null) return '';
	const div = document.createElement('div');
	div.textContent = s;
	return div.innerHTML;
}

function formatDateTime(iso) {
	const d = new Date(iso);
	if (Number.isNaN(d.getTime())) return iso;
	return d.toLocaleString(undefined, {
		weekday: 'short',
		year: 'numeric',
		month: 'short',
		day: 'numeric',
		hour: '2-digit',
		minute: '2-digit',
	});
}

function screeningBookable(s) {
	if (s.screening_status !== 'selling') return false;
	if (s.available_seats <= 0) return false;
	const start = new Date(s.starts_at);
	return start.getTime() > Date.now();
}

function statusHint(s) {
	if (s.available_seats <= 0) return 'Sold out';
	switch (s.screening_status) {
		case 'scheduled':
			return 'Tickets not on sale yet';
		case 'selling':
			return new Date(s.starts_at) <= Date.now() ? 'Screening has started' : '';
		case 'sold_out':
			return 'Sold out';
		case 'finished':
			return 'Ended';
		case 'cancelled':
			return 'Cancelled';
		default:
			return 'Not available';
	}
}

function buildQuery() {
	const params = new URLSearchParams();
	const q = document.getElementById('search-input').value.trim();
	if (q) params.set('search', q);
	const genre = document.getElementById('genre-select')?.value;
	if (genre) params.set('genre', genre);
	if (document.getElementById('now-showing-only')?.checked) {
		params.set('nowShowing', 'true');
	}
	params.set('limit', '60');
	return params.toString();
}

async function fetchMovies() {
	const status = document.getElementById('list-status');
	status.textContent = 'Loading…';
	const qs = buildQuery();
	const res = await fetch(`${API}/movies?${qs}`);
	if (!res.ok) {
		status.textContent = 'Could not load movies.';
		return [];
	}
	const data = await res.json();
	status.textContent = `${data.length} movie(s)`;
	return data;
}

function renderGenreFilters() {
	const wrap = document.getElementById('genre-filters');
	wrap.innerHTML = `
		<label class="genre-select-label">
			<span class="visually-hidden">Filter by genre</span>
			<select id="genre-select" class="genre-select">
				<option value="">All genres</option>
				${GENRES.map(g => `<option value="${escapeHtml(g)}">${escapeHtml(g)}</option>`).join('')}
			</select>
		</label>
	`;
	document
		.getElementById('genre-select')
		.addEventListener('change', () => loadList());
}

function genrePills(genres) {
	if (!genres || !genres.length) return '';
	return genres
		.map(g => `<span class="genre-pill">${escapeHtml(g.name)}</span>`)
		.join('');
}

function renderMovieGrid(movies) {
	const grid = document.getElementById('movie-grid');
	grid.innerHTML = movies
		.map(m => {
			const hue = hueFromId(m.movie_id);
			const initials = m.title
				.split(/\s+/)
				.slice(0, 2)
				.map(w => w[0])
				.join('')
				.toUpperCase();
			const tag = m.tagline ? escapeHtml(m.tagline) : '—';
			return `
			<article class="movie-card" data-movie-id="${m.movie_id}">
				<div class="movie-card-top">
					<div class="poster-placeholder" style="background:hsl(${hue},55%,52%)">${escapeHtml(initials)}</div>
					<div class="card-meta">
						<h2 class="card-title"><a href="#/movie/${m.movie_id}">${escapeHtml(m.title)}</a></h2>
						<p class="card-tagline">${tag}</p>
						<p class="card-facts">${escapeHtml(m.director_name)} · ${m.release_year} · ${escapeHtml(m.age_rating)} · ${m.duration_minutes} min</p>
						<div class="genre-pills">${genrePills(m.genres)}</div>
					</div>
				</div>
				<div class="card-actions">
					<button type="button" class="btn toggle-screenings" data-movie-id="${m.movie_id}">Screenings</button>
				</div>
				<div class="screenings-block hidden" data-screenings-for="${m.movie_id}">
					<h3>Screenings</h3>
					<div class="screenings-inner" data-screenings-inner="${m.movie_id}"></div>
				</div>
			</article>
		`;
		})
		.join('');

	grid.querySelectorAll('.toggle-screenings').forEach(btn => {
		btn.addEventListener('click', async e => {
			const id = Number(e.currentTarget.dataset.movieId);
			const block = grid.querySelector(`[data-screenings-for="${id}"]`);
			const inner = grid.querySelector(`[data-screenings-inner="${id}"]`);
			const hidden = block.classList.toggle('hidden');
			if (!hidden) {
				if (!screeningsCache.has(id)) {
					inner.textContent = 'Loading…';
					const res = await fetch(`${API}/movies/${id}/screenings`);
					if (!res.ok) {
						inner.textContent = 'Could not load screenings.';
						return;
					}
					const rows = await res.json();
					screeningsCache.set(id, rows);
				}
				inner.innerHTML = renderScreenings(screeningsCache.get(id), id);
				wireBookingForms(inner);
			}
		});
	});
}

function renderScreenings(rows, movieId) {
	if (!rows.length) return '<p class="book-msg">No screenings listed.</p>';
	return rows
		.map(s => {
			const bookable = screeningBookable(s);
			const hint = bookable
				? ''
				: escapeHtml(statusHint(s) || 'Not available for booking');
			const badgeClass = `status-badge status-${escapeHtml(s.screening_status)}`;
			return `
			<div class="screening-row" data-screening-id="${s.screening_id}">
				<div class="screening-info">
					<p class="screening-when">${formatDateTime(s.starts_at)} · ${escapeHtml(s.hall_name)}</p>
					<p class="screening-meta">
						<span class="${badgeClass}">${escapeHtml(s.screening_status)}</span>
						<span class="screening-seats">Seats: ${s.available_seats} / ${s.total_seats}</span>
					</p>
					${hint ? `<p class="book-msg screening-hint">${hint}</p>` : ''}
				</div>
				<div class="screening-action">
					${
						bookable
							? `
					<form class="booking-mini" data-screening-id="${s.screening_id}" data-movie-id="${movieId}">
						<input type="text" name="customerName" placeholder="Your name" required maxlength="100" />
						<input type="email" name="customerEmail" placeholder="Email (optional)" maxlength="255" />
						<div class="booking-mini-row">
							<input type="number" name="seatCount" min="1" max="${s.available_seats}" value="1" required aria-label="Number of seats" />
							<button type="submit" class="btn btn-primary">Buy</button>
						</div>
						<span class="book-msg" data-book-feedback></span>
					</form>
					`
							: ''
					}
				</div>
			</div>
		`;
		})
		.join('');
}

function wireBookingForms(container) {
	container.querySelectorAll('form.booking-mini').forEach(form => {
		form.addEventListener('submit', async ev => {
			ev.preventDefault();
			const fd = new FormData(form);
			const feedback = form.querySelector('[data-book-feedback]');
			feedback.textContent = '';
			feedback.className = 'book-msg';
			const screeningId = Number(form.dataset.screeningId);
			const body = {
				screeningId,
				customerName: fd.get('customerName').trim(),
				customerEmail: (fd.get('customerEmail') || '').trim(),
				seatCount: Number(fd.get('seatCount')),
			};
			if (!body.customerEmail) delete body.customerEmail;
			const res = await fetch(`${API}/bookings`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(body),
			});
			const data = await res.json().catch(() => ({}));
			if (!res.ok) {
				const msg = data.message || 'Booking failed';
				feedback.textContent = msg;
				feedback.classList.add('error');
				showToast(msg, 'error');
				return;
			}
			const seatLabel = body.seatCount === 1 ? 'seat' : 'seats';
			showToast(
				`Booked ${body.seatCount} ${seatLabel}! Confirmation #${data.ticket_booking_id}`,
				'success',
			);
			feedback.textContent = `Booked! Confirmation #${data.ticket_booking_id}`;
			feedback.classList.add('ok');
			screeningsCache.delete(Number(form.dataset.movieId));
			const inner = form.closest('.screenings-inner');
			if (inner) {
				const mid = Number(form.dataset.movieId);
				const res2 = await fetch(`${API}/movies/${mid}/screenings`);
				if (res2.ok) {
					const rows = await res2.json();
					screeningsCache.set(mid, rows);
					inner.innerHTML = renderScreenings(rows, mid);
					wireBookingForms(inner);
				}
			}
		});
	});
}

async function loadList() {
	const movies = await fetchMovies();
	renderMovieGrid(movies);
}

function showList() {
	document.getElementById('list-view').classList.remove('hidden');
	document.getElementById('detail-view').classList.add('hidden');
	document.getElementById('detail-view').setAttribute('aria-hidden', 'true');
}

function showDetail() {
	document.getElementById('list-view').classList.add('hidden');
	document.getElementById('detail-view').classList.remove('hidden');
	document.getElementById('detail-view').setAttribute('aria-hidden', 'false');
}

async function loadDetail(movieId) {
	showDetail();
	const status = document.getElementById('detail-status');
	const content = document.getElementById('detail-content');
	status.textContent = 'Loading…';
	content.innerHTML = '';
	const res = await fetch(`${API}/movies/${movieId}`);
	if (!res.ok) {
		status.textContent = 'Movie not found.';
		return;
	}
	const m = await res.json();
	status.textContent = '';
	const hue = hueFromId(m.movie_id);
	const initials = m.title
		.split(/\s+/)
		.slice(0, 2)
		.map(w => w[0])
		.join('')
		.toUpperCase();
	const synopsis = m.synopsis
		? escapeHtml(m.synopsis)
		: '<em class="synopsis">No synopsis in the catalog for this title.</em>';
	const tag = m.tagline ? escapeHtml(m.tagline) : '—';
	const castRows = (m.cast || [])
		.map(
			c => `
		<tr>
			<td>${escapeHtml(c.full_name)}${c.is_lead_role ? '<span class="lead-badge">Lead</span>' : ''}</td>
			<td>${c.role_name != null ? escapeHtml(c.role_name) : '—'}</td>
		</tr>
	`,
		)
		.join('');

	const genres = (m.genres || [])
		.map(g => `<span class="genre-pill">${escapeHtml(g.name)}</span>`)
		.join('');

	content.innerHTML = `
		<div class="detail-hero">
			<div class="detail-poster" style="background:hsl(${hue},55%,52%)">${escapeHtml(initials)}</div>
			<div>
				<h1>${escapeHtml(m.title)}</h1>
				<p class="detail-facts">${escapeHtml(m.director_name)}${m.director_country ? ` · ${escapeHtml(m.director_country)}` : ''} · ${m.release_year} · ${escapeHtml(m.age_rating)} · ${m.duration_minutes} min</p>
				<p class="synopsis"><strong>Tagline:</strong> ${tag}</p>
				<div class="genre-pills" style="margin-top:0.5rem">${genres}</div>
			</div>
		</div>
		<section class="synopsis"><h2 class="aside-title" style="margin-bottom:0.5rem">Synopsis</h2>${synopsis}</section>
		<table class="cast-table">
			<thead><tr><th>Actor</th><th>Role</th></tr></thead>
			<tbody>${castRows || '<tr><td colspan="2">No cast listed.</td></tr>'}</tbody>
		</table>
		<div style="margin-top:2rem" id="detail-screenings-wrap">
			<button type="button" class="btn toggle-detail-screenings" data-movie-id="${m.movie_id}">Screenings</button>
			<div class="screenings-block hidden" id="detail-screenings-block" aria-hidden="true">
				<h3>Screenings</h3>
				<div id="detail-screenings-inner" class="screenings-inner"></div>
			</div>
		</div>
	`;

	const detailBlock = document.getElementById('detail-screenings-block');
	const detailInner = document.getElementById('detail-screenings-inner');
	const detailToggle = content.querySelector('.toggle-detail-screenings');
	detailToggle.addEventListener('click', async () => {
		const wasHidden = detailBlock.classList.contains('hidden');
		detailBlock.classList.toggle('hidden');
		detailBlock.setAttribute(
			'aria-hidden',
			detailBlock.classList.contains('hidden') ? 'true' : 'false',
		);
		if (!wasHidden) return;
		const mid = Number(detailToggle.dataset.movieId);
		if (!screeningsCache.has(mid)) {
			detailInner.textContent = 'Loading…';
			const resS = await fetch(`${API}/movies/${mid}/screenings`);
			if (!resS.ok) {
				detailInner.textContent = 'Could not load screenings.';
				return;
			}
			const screenings = await resS.json();
			screeningsCache.set(mid, screenings);
		}
		detailInner.innerHTML = renderScreenings(screeningsCache.get(mid), mid);
		wireBookingForms(detailInner);
	});
}

function parseRoute() {
	const h = window.location.hash.replace(/^#/, '');
	const m = h.match(/^\/movie\/(\d+)$/);
	return m ? Number(m[1]) : null;
}

function onRoute() {
	const id = parseRoute();
	if (id) {
		loadDetail(id);
	} else {
		showList();
		loadList();
	}
}

document.getElementById('search-input').addEventListener('input', () => {
	clearTimeout(searchDebounce);
	searchDebounce = setTimeout(() => loadList(), 320);
});

document
	.getElementById('now-showing-only')
	.addEventListener('change', () => loadList());

document.getElementById('back-btn').addEventListener('click', () => {
	window.location.hash = '#/';
});

window.addEventListener('hashchange', onRoute);

renderGenreFilters();
onRoute();
