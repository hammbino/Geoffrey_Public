import assert from 'node:assert/strict';
import test from 'node:test';
import { buildBriefingContext, eventOverlapsDay, localDayWindow } from '../src/briefing-context.js';
import * as google from '../src/providers/google.js';
import * as microsoft from '../src/providers/microsoft.js';

async function inZone(zone, action) {
  const prior = process.env.TZ;
  process.env.TZ = zone;
  try { return await action(); }
  finally { if (prior === undefined) delete process.env.TZ; else process.env.TZ = prior; }
}
const monday = new Date('2026-10-19T20:07:00Z');
const event = (id, start, end, extra = {}) => ({ id, summary: id, start, end, ...extra });
const account = { id: 'work', email: 'fixture@example.test', provider: 'google' };

test('chat gets live dated context and can read beyond the bounded unread snapshot', async () => inZone('America/Denver', async () => {
  const fixture = source();
  const packet = await buildBriefingContext({ ...fixture, task: 'ask' });
  assert.match(packet, /TODAY'S LOCAL DATE: 2026-10-19/);
  assert.match(packet, /limited snapshot.*not a complete inbox search/);
  assert.match(packet, /using the geoffrey_readonly tools/);
  assert.match(packet, /does not establish whether a reply has been sent/);
  assert.doesNotMatch(packet, /Do not call email or calendar tools/);
}));
function source(events = [], extra = {}) {
  const calls = [];
  const provider = {
    searchMessages: async () => ({ messages: [] }),
    listEvents: async (_, options) => { calls.push(options); return { events, ...extra }; },
  };
  return { calls, getAccount: () => account, providers: { google: provider }, accounts: [account], now: monday };
}

test('a 2:07 PM Monday briefing uses all of Monday and excludes Tuesday recurring events', async () => inZone('America/Denver', async () => {
  const fixture = source([
    event('Monday meeting', '2026-10-19T11:00:00-06:00', '2026-10-19T12:00:00-06:00'),
    event('Work Out', '2026-10-20T08:00:00-06:00', '2026-10-20T09:00:00-06:00'),
    event('Alumni group call', '2026-10-20T11:00:00-06:00', '2026-10-20T12:00:00-06:00'),
    event('Community call', '2026-10-20T13:00:00-06:00', '2026-10-20T14:00:00-06:00'),
  ]);
  const packet = await buildBriefingContext(fixture);
  assert.equal(fixture.calls[0].time_min, '2026-10-19T06:00:00.000Z');
  assert.equal(fixture.calls[0].time_max, '2026-10-20T06:00:00.000Z');
  assert.match(packet, /TODAY'S LOCAL DATE: 2026-10-19; time zone: America\/Denver/);
  assert.match(packet, /Monday meeting/);
  assert.match(packet, /Mon, Oct 19, 2026, 11:00 AM MDT/);
  assert.match(packet, /12:00 PM MDT/);
  assert.match(packet, /already ended/);
  assert.doesNotMatch(packet, /Alumni group call|Work Out|Community call/);
}));

test('local day boundaries hold near UTC midnight, in positive offsets, and through DST', async () => {
  await inZone('America/Denver', () => {
    const late = localDayWindow(new Date('2026-10-20T05:59:00Z'));
    assert.equal(late.date, '2026-10-19');
    assert.equal(late.end, '2026-10-20T06:00:00.000Z');
    const next = localDayWindow(new Date('2026-10-20T06:00:00Z'));
    assert.equal(next.date, '2026-10-20');
    for (const [when, hours] of [['2026-03-08T18:00:00Z', 23], ['2026-11-01T18:00:00Z', 25]]) {
      const range = localDayWindow(new Date(when));
      assert.equal((Date.parse(range.end) - Date.parse(range.start)) / 3600000, hours);
    }
  });
  await inZone('Asia/Kathmandu', () => {
    const range = localDayWindow(new Date('2026-10-19T20:00:00Z'));
    assert.equal(range.date, '2026-10-20');
    assert.equal(range.start, '2026-10-19T18:15:00.000Z');
    assert.equal(range.end, '2026-10-20T18:15:00.000Z');
  });
});

test('all-day and overnight events intersect the local day; exclusive end, cancelled, and declined events do not', async () => inZone('America/Denver', async () => {
  const range = localDayWindow(monday);
  assert.equal(eventOverlapsDay(event('all day', '2026-10-19', '2026-10-20'), range), true);
  assert.equal(eventOverlapsDay(event('yesterday', '2026-10-18', '2026-10-19'), range), false);
  assert.equal(eventOverlapsDay(event('tomorrow', '2026-10-20', '2026-10-21'), range), false);
  assert.equal(eventOverlapsDay(event('overnight', '2026-10-18T23:00:00-06:00', '2026-10-19T01:00:00-06:00'), range), true);
  assert.equal(eventOverlapsDay(event('ended at midnight', '2026-10-18T23:00:00-06:00', '2026-10-19T00:00:00-06:00'), range), false);
  assert.equal(eventOverlapsDay(event('starts tomorrow', '2026-10-20T00:00:00-06:00', '2026-10-20T01:00:00-06:00'), range), false);
  for (const extra of [{ status: 'cancelled' }, { is_cancelled: true }, { self_response: 'declined' }]) {
    assert.equal(eventOverlapsDay(event('not attending', '2026-10-19T17:00:00Z', '2026-10-19T18:00:00Z', extra), range), false);
  }
  const packet = await buildBriefingContext(source([event('All day', '2026-10-19', '2026-10-20')]));
  assert.match(packet, /2026-10-19 \(all day\)/);
  assert.match(packet, /2026-10-20 \(exclusive all-day end date\)/);
}));

test('one failed credential/calendar preserves healthy facts and never claims the failed account is free', async () => inZone('America/Denver', async () => {
  const fixture = source([event('Verified meeting', '2026-10-19T15:00:00Z', '2026-10-19T16:00:00Z')]);
  fixture.accounts.push({ ...account, id: 'broken' });
  fixture.getAccount = id => { if (id === 'broken') throw new Error('Credential unavailable'); return account; };
  const packet = await buildBriefingContext(fixture);
  assert.match(packet, /Verified meeting/);
  assert.match(packet, /Could not access broken.*calendar is unverified/);
  const failed = source();
  failed.providers.google.listEvents = async () => { throw new Error('network unavailable'); };
  const warning = await buildBriefingContext(failed);
  assert.match(warning, /schedule is unverified; do not reconstruct it from memory/);
  assert.doesNotMatch(warning, /- No verified events returned for this local date/);
}));

test('truncated calendar data cannot establish free time and tomorrow email invitations cannot establish a meeting', async () => inZone('America/Denver', async () => {
  const fixture = source([], { has_more: true });
  fixture.providers.google.searchMessages = async () => ({ messages: [{ subject: 'Tomorrow alumni invitation', from: 'fixture@example.test', date: '2026-10-19' }] });
  const packet = await buildBriefingContext(fixture);
  assert.match(packet, /coverage may be incomplete.*Do not infer free time/);
  assert.match(packet, /email text does not establish a confirmed meeting today/);
  assert.match(packet, /past briefings into today's schedule or meeting-preparation priorities/);
}));

test('Outlook calendar timestamps retain UTC offsets and end times instead of becoming local floating times', async () => {
  const previous = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options = {}) => {
    if (String(url).includes('oauth2')) return new Response(JSON.stringify({ access_token: 'fixture-token', expires_in: 3600 }));
    calls.push({ url: String(url), headers: options.headers });
    return new Response(JSON.stringify({ value: [{ id: 'event', subject: 'UTC meeting', start: { dateTime: '2026-10-20T01:00:00.0000000', timeZone: 'UTC' }, end: { dateTime: '2026-10-20T02:00:00.0000000', timeZone: 'UTC' }, responseStatus: { response: 'accepted' } }] }));
  };
  try {
    const result = await microsoft.listEvents({ id: 'time-zone-outlook', provider: 'microsoft', client_id: 'fixture', refresh_token: 'fixture' }, { time_min: '2026-10-19T06:00:00Z', time_max: '2026-10-20T06:00:00Z' });
    assert.equal(calls[0].headers.Prefer, 'outlook.timezone="UTC"');
    assert.equal(new Date(result.events[0].start).toISOString(), '2026-10-20T01:00:00.000Z');
    assert.equal(new Date(result.events[0].end).toISOString(), '2026-10-20T02:00:00.000Z');
    await inZone('America/Denver', () => assert.equal(eventOverlapsDay(result.events[0], localDayWindow(monday)), true));
  } finally { globalThis.fetch = previous; }
});

test('Google preserves cancellation/attendance and pagination metadata for the verified briefing', async () => {
  const previous = globalThis.fetch;
  globalThis.fetch = async url => {
    if (String(url).includes('oauth2')) return new Response(JSON.stringify({ access_token: 'fixture-token', expires_in: 3600 }));
    return new Response(JSON.stringify({ nextPageToken: 'next', items: [{ id: 'event', summary: 'Declined event', status: 'confirmed', start: { dateTime: '2026-10-19T11:00:00-06:00' }, end: { dateTime: '2026-10-19T12:00:00-06:00' }, attendees: [{ self: true, responseStatus: 'declined' }] }] }));
  };
  try {
    const result = await google.listEvents({ id: 'time-zone-google', provider: 'google', client_id: 'fixture', refresh_token: 'fixture' }, {});
    assert.equal(result.has_more, true);
    assert.equal(result.events[0].self_response, 'declined');
    assert.equal(result.events[0].end, '2026-10-19T12:00:00-06:00');
  } finally { globalThis.fetch = previous; }
});
