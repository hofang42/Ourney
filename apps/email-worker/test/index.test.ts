import { afterEach, describe, expect, it, vi } from 'vitest';
import worker from '../src/index';
import { FakeKV, humanHeaders, makeEnv } from './helpers';

function fakeMessage(forward = vi.fn(async () => ({}))) {
  return {
    from: 'lan@gmail.com',
    to: 'support@ourney.tech',
    headers: humanHeaders(),
    forward,
  } as unknown as ForwardableEmailMessage;
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('email handler', () => {
  it('forwards before replying', async () => {
    const order: string[] = [];
    const forward = vi.fn(async () => {
      order.push('forward');
      return {};
    });
    vi.stubGlobal('fetch', vi.fn(async () => {
      order.push('reply');
      return new Response('{}', { status: 200 });
    }));
    vi.spyOn(console, 'log').mockImplementation(() => {});

    await worker.email(fakeMessage(forward), makeEnv());

    expect(forward).toHaveBeenCalledWith('owner-inbox@example.com');
    expect(order).toEqual(['forward', 'reply']);
  });

  it('still forwards when the reply fails, and logs no address', async () => {
    const forward = vi.fn(async () => ({}));
    vi.stubGlobal('fetch', vi.fn(async () => {
      throw new Error('network down');
    }));
    const error = vi.spyOn(console, 'error').mockImplementation(() => {});

    await expect(
      worker.email(fakeMessage(forward), makeEnv(new FakeKV())),
    ).resolves.toBeUndefined();

    expect(forward).toHaveBeenCalledTimes(1);
    const logged = error.mock.calls.flat().join(' ');
    expect(logged).toContain('network down');
    expect(logged).not.toContain('lan@gmail.com');
  });

  it('lets a forward failure surface', async () => {
    const forward = vi.fn(async () => {
      throw new Error('destination not verified');
    });
    await expect(
      worker.email(fakeMessage(forward), makeEnv()),
    ).rejects.toThrow('destination not verified');
  });
});
