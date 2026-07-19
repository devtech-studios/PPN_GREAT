import type { Page } from '@playwright/test';

export const pacing = {
  actionSlowMoMs: 1_000,
  normalMs: 3_000,
  importantMs: 4_000,
  errorMs: 6_000,
  finalMs: 10_000,
} as const;

export type VideoCardKind = 'normal' | 'important' | 'success' | 'error' | 'final';

const cardTheme: Record<VideoCardKind, { color: string; border: string; label: string }> = {
  normal: { color: '#E2E8F0', border: '#64748B', label: 'STEP | ขั้นตอน' },
  important: { color: '#FEF3C7', border: '#F59E0B', label: 'IMPORTANT | จุดสำคัญ' },
  success: { color: '#DCFCE7', border: '#22C55E', label: 'SUCCESS | สำเร็จ' },
  error: { color: '#FEE2E2', border: '#EF4444', label: 'ERROR CHECK | ตรวจเคสผิดปกติ' },
  final: { color: '#DBEAFE', border: '#2563EB', label: 'SUMMARY | สรุป' },
};

function durationFor(kind: VideoCardKind): number {
  if (kind === 'error') return pacing.errorMs;
  if (kind === 'final') return pacing.finalMs;
  if (kind === 'important' || kind === 'success') return pacing.importantMs;
  return pacing.normalMs;
}

export async function showVideoCard(
  page: Page,
  kind: VideoCardKind,
  title: string,
  lines: string[],
  durationMs = durationFor(kind),
): Promise<void> {
  const theme = cardTheme[kind];
  await page.evaluate(
    ({ titleText, detailLines, colors }) => {
      document.getElementById('__ppn_adversarial_video_card__')?.remove();
      const card = document.createElement('section');
      card.id = '__ppn_adversarial_video_card__';
      card.setAttribute('role', 'status');
      card.style.cssText = [
        'position:fixed', 'left:50%', 'top:7%', 'transform:translateX(-50%)',
        'z-index:2147483647', 'width:min(980px,88vw)', 'padding:24px 30px',
        `background:${colors.color}`, `border:4px solid ${colors.border}`,
        'border-radius:18px', 'box-shadow:0 24px 70px rgba(15,23,42,.38)',
        'font-family:Arial,"Noto Sans Thai",sans-serif', 'color:#0F172A',
        'pointer-events:none',
      ].join(';');
      const label = document.createElement('div');
      label.textContent = colors.label;
      label.style.cssText = `font-size:17px;font-weight:800;color:${colors.border};margin-bottom:8px`;
      const heading = document.createElement('div');
      heading.textContent = titleText;
      heading.style.cssText = 'font-size:28px;font-weight:800;line-height:1.25;margin-bottom:12px';
      const list = document.createElement('ul');
      list.style.cssText = 'font-size:20px;line-height:1.45;margin:0;padding-left:26px';
      for (const line of detailLines) {
        const item = document.createElement('li');
        item.textContent = line;
        list.appendChild(item);
      }
      card.append(label, heading, list);
      document.body.appendChild(card);
    },
    { titleText: title, detailLines: lines, colors: theme },
  );
  await page.waitForTimeout(durationMs);
  await page.evaluate(() => document.getElementById('__ppn_adversarial_video_card__')?.remove());
}
