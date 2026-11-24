import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, supabase } from '../lib/adminRpc'
import {
  SQL_FIXTURE_AUDIT_LIST,
  SQL_FIXTURE_FILTER_BLOCKED,
  SQL_FIXTURE_FILTER_PASS,
  SQL_FIXTURE_JOURNEYS_LIST,
  SQL_FIXTURE_JOURNEY_STATS,
  SQL_FIXTURE_MODERATION_DETAIL,
  SQL_FIXTURE_MODERATION_QUEUE,
  SQL_FIXTURE_OVERVIEW,
  SQL_FIXTURE_SYSTEM_HEALTH,
  SQL_FIXTURE_USERS_LIST,
  SQL_FIXTURE_USER_DETAIL,
  SQL_FIXTURE_WAITLIST_SUMMARY,
} from './fixtures'

describe('0023_admin.sql RPC Contract Alignment (adminRpc.ts)', () => {
  const rpcMock = vi.fn()

  beforeEach(() => {
    vi.restoreAllMocks()
    rpcMock.mockReset()
    vi.spyOn(supabase, 'schema').mockReturnValue({
      rpc: rpcMock,
    } as unknown as ReturnType<typeof supabase.schema>)
  })

  it('maps admin.overview_stats exact SQL JSON (alerts, nested kpis, daily_growth, daily_habit_pulse, activation_funnel_7d, template_mix)', async () => {
    rpcMock.mockResolvedValueOnce({
      data: SQL_FIXTURE_OVERVIEW,
      error: null,
    })

    const res = await adminApi.overviewStats(30, 'Asia/Ho_Chi_Minh')
    expect(rpcMock).toHaveBeenCalledWith('overview_stats', {
      p_days: 30,
      p_tz: 'Asia/Ho_Chi_Minh',
    })
    expect(res.alerts.open_reports).toBe(2)
    expect(res.kpis.users.live_profiles).toBe(482)
    expect(res.kpis.waitlist.total).toBe(1280)
    expect(res.daily_growth[0]).toEqual({
      day: '2026-11-18',
      new_profiles: 14,
      new_waitlist: 32,
    })
    expect(res.daily_habit_pulse[0].live_checkins).toBe(151)
    expect(res.activation_funnel_7d[4].step).toBe('first_live_checkin')
    expect(res.template_mix[0]).toEqual({
      template: 'weight_loss',
      active_journeys: 128,
    })
  })

  it('preserves kpis.feature_requests: null when Migration 0024 is not installed (no fake fallback)', async () => {
    rpcMock.mockResolvedValueOnce({
      data: {
        ...SQL_FIXTURE_OVERVIEW,
        kpis: {
          ...SQL_FIXTURE_OVERVIEW.kpis,
          feature_requests: null,
        },
      },
      error: null,
    })

    const res = await adminApi.overviewStats(7, 'UTC')
    expect(res.kpis.feature_requests).toBeNull()
  })

  it('maps admin.list_moderation_queue, admin.get_moderation_item, and admin.reveal_reported_media (filtering duplicate thumb when photo exists)', async () => {
    rpcMock
      .mockResolvedValueOnce({
        data: SQL_FIXTURE_MODERATION_QUEUE,
        error: null,
      })
      .mockResolvedValueOnce({
        data: SQL_FIXTURE_MODERATION_DETAIL,
        error: null,
      })
      .mockResolvedValueOnce({
        data: {
          queue_id: 'mq-01',
          expires_at: '2026-11-24T15:00:00Z',
          ttl_seconds: 300,
          objects: [
            {
              bucket: 'media',
              path: 'checkins/j1/usr-88/chk-901.jpg',
              kind: 'photo',
            },
            {
              bucket: 'media',
              path: 'checkins/j1/usr-88/chk-901_t.jpg',
              kind: 'thumb',
            },
            {
              bucket: 'media',
              path: 'checkins/j1/usr-88/chk-901_p.jpg',
              kind: 'partner_photo',
            },
          ],
        },
        error: null,
      })

    const createSignedUrlMock = vi.fn().mockImplementation((p: string) =>
      Promise.resolve({
        data: { signedUrl: `https://signed.example/${p}` },
        error: null,
      }),
    )
    vi.spyOn(supabase.storage, 'from').mockReturnValue({
      createSignedUrl: createSignedUrlMock,
    } as unknown as ReturnType<typeof supabase.storage.from>)

    const listRes = await adminApi.listModerationQueue({ p_status: 'open' })
    expect(listRes.summary.median_handle_hours_30d).toBe(1.45)
    expect(listRes.items[0].auto_quarantined).toBe(false)
    expect(listRes.items[1].reason).toBeNull()

    const detailRes = await adminApi.getModerationItem('mq-01')
    expect(detailRes.reported_content.target_type).toBe('checkin')
    if (detailRes.reported_content.target_type === 'checkin') {
      expect(detailRes.reported_content.caption).toBe(
        'Reported check-in caption text only',
      )
    }

    const revealRes = await adminApi.revealReportedMedia('mq-01', 'SLA review')
    expect(revealRes.objects).toHaveLength(2)
    expect(revealRes.objects.map((o) => o.kind)).toEqual([
      'photo',
      'partner_photo',
    ])
    expect(createSignedUrlMock).toHaveBeenCalledWith(
      'checkins/j1/usr-88/chk-901.jpg',
      120,
    )
    expect(revealRes.objects[0].signed_url).toBe(
      'https://signed.example/checkins/j1/usr-88/chk-901.jpg',
    )
  })

  it('maps admin.test_content_filter { blocked, term, matches } accurately for clean and blocked strings', async () => {
    rpcMock
      .mockResolvedValueOnce({ data: SQL_FIXTURE_FILTER_PASS, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_FILTER_BLOCKED, error: null })

    const clean = await adminApi.testContentFilter('Chào buổi sáng tốt lành')
    expect(clean.blocked).toBe(false)
    expect(clean.term).toBeNull()

    const blocked = await adminApi.testContentFilter('Click scam link now')
    expect(blocked.blocked).toBe(true)
    expect(blocked.term).toBe('scam link')
  })

  it('maps admin.waitlist_summary, admin.list_users, admin.get_user_detail, admin.journey_stats, admin.list_journeys, admin.list_audit_log, and admin.system_health', async () => {
    rpcMock
      .mockResolvedValueOnce({
        data: SQL_FIXTURE_WAITLIST_SUMMARY,
        error: null,
      })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_USERS_LIST, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_USER_DETAIL, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_JOURNEY_STATS, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_JOURNEYS_LIST, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_AUDIT_LIST, error: null })
      .mockResolvedValueOnce({ data: SQL_FIXTURE_SYSTEM_HEALTH, error: null })

    const wl = await adminApi.waitlistSummary(30)
    expect(wl.lang_vi).toBe(1090)
    expect(wl.mail_sent).toBe(1274)
    expect(wl.by_source[0].source).toBe('landing_hero')

    const users = await adminApi.listUsers({})
    expect(users.items[0].id).toBe('usr-10')
    expect(users.items[0].active_journeys_count).toBe(2)

    const userDetail = await adminApi.getUserDetail('usr-10')
    expect(userDetail.id).toBe('usr-10')
    expect(userDetail.activity.total_checkins).toBe(48)
    expect(userDetail.trust.audit_history).toHaveLength(1)

    const jStats = await adminApi.journeyStats()
    expect(jStats.active).toBe(612)
    expect(jStats.public_links_count).toBe(47)

    const jList = await adminApi.listJourneys({})
    expect(jList.items[1].max_members).toBeNull()
    expect(jList.items[0].layout).toBe('accountability_squad')

    const audit = await adminApi.listAuditLog({})
    expect(audit.items).toHaveLength(2)
    expect(audit.next_before_id).toBeNull()

    const health = await adminApi.systemHealth()
    expect(health.moderation_notifications.unnotified_open_count).toBe(1)
    expect(health.storage_purge.sample_errors[0].path_prefix).toBe(
      'checkins/...',
    )
  })
})
