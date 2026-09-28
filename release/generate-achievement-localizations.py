#!/usr/bin/env python3
"""Create and validate seven-locale Game Center achievement copy.

Run once with: python3 release/generate-achievement-localizations.py
The script refuses to overwrite an existing output file.
"""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
LOCALES = ("ja", "en-US", "es-ES", "fr", "ko", "pt-BR", "zh-Hans")
DIFFICULTIES = ("easy", "normal", "strong", "oni")
STREAKS = (3, 5, 10, 15, 20, 25, 30)
WINS = (1, 3, 5, 10, 30, 100, 1000, 10000)

DIFFICULTY_COPY = {
    "ja": [
        ("ひよっこ", "やさしいCPUに勝とう", "やさしいCPUに勝利した"),
        ("一人前", "ふつうのCPUに勝とう", "ふつうのCPUに勝利した"),
        ("達人", "つよいCPUに勝とう", "つよいCPUに勝利した"),
        ("レジェンド", "おにのCPUに勝とう", "おにのCPUに勝利した"),
    ],
    "en-US": [
        ("Rookie", "Defeat the Easy CPU.", "Defeated the Easy CPU."),
        ("Skilled Player", "Beat the Normal CPU", "Defeated the Normal CPU"),
        ("Master", "Beat the Strong CPU", "Defeated the Strong CPU"),
        ("Legend", "Beat the Oni CPU", "Defeated the Oni CPU"),
    ],
    "es-ES": [
        ("Novato", "Vence a la CPU en Fácil.", "Has vencido a la CPU en Fácil."),
        ("Jugador experto", "Vence a la CPU normal", "Venciste a la CPU normal"),
        ("Maestro", "Vence a la CPU difícil", "Venciste a la CPU difícil"),
        ("Leyenda", "Vence a la CPU Oni", "Venciste a la CPU Oni"),
    ],
    "fr": [
        ("Débutant", "Bats l'IA en mode Facile.", "Tu as battu l'IA en mode Facile."),
        ("Joueur confirmé", "Battez l’IA normale", "Vous avez battu l’IA normale"),
        ("Maître", "Battez l’IA forte", "Vous avez battu l’IA forte"),
        ("Légende", "Battez l’IA Oni", "Vous avez battu l’IA Oni"),
    ],
    "ko": [
        ("초보", "쉬움 난이도 CPU를 이기세요.", "쉬움 난이도 CPU를 이겼습니다."),
        ("한 사람 몫", "보통 CPU를 이겨 보세요", "보통 CPU에게 승리했습니다"),
        ("달인", "강한 CPU를 이겨 보세요", "강한 CPU에게 승리했습니다"),
        ("레전드", "오니 CPU를 이겨 보세요", "오니 CPU에게 승리했습니다"),
    ],
    "pt-BR": [
        ("Novato", "Vença a CPU no nível Fácil.", "Você venceu a CPU no nível Fácil."),
        ("Jogador experiente", "Vença a CPU normal", "Você venceu a CPU normal"),
        ("Mestre", "Vença a CPU forte", "Você venceu a CPU forte"),
        ("Lenda", "Vença a CPU Oni", "Você venceu a CPU Oni"),
    ],
    "zh-Hans": [
        ("新手", "击败简单难度的电脑。", "已击败简单难度的电脑。"),
        ("独当一面", "击败普通电脑", "击败了普通电脑"),
        ("达人", "击败强力电脑", "击败了强力电脑"),
        ("传奇", "击败鬼级电脑", "击败了鬼级电脑"),
    ],
}


def number(value: int, locale: str) -> str:
    if value < 1000:
        return str(value)
    if locale in ("es-ES", "pt-BR"):
        return f"{value:,}".replace(",", ".")
    if locale == "fr":
        return f"{value:,}".replace(",", " ")
    return f"{value:,}"


def streak_copy(value: int, locale: str) -> tuple[str, str, str]:
    n = number(value, locale)
    return {
        "ja": (f"連戦連勝 {n}", f"CPU戦で{n}連勝しよう", f"CPU戦で{n}連勝した"),
        "en-US": (f"{n}-Win Streak", f"Win {n} CPU games in a row", f"Won {n} CPU games in a row"),
        "es-ES": (f"Racha de {n} victorias", f"Gana {n} partidas seguidas contra la CPU", f"Ganaste {n} partidas seguidas contra la CPU"),
        "fr": (f"Série de {n} victoires", f"Gagnez {n} parties de suite contre l’IA", f"Vous avez gagné {n} parties de suite contre l’IA"),
        "ko": (f"{n}연승", f"CPU전에서 {n}연승하세요", f"CPU전에서 {n}연승을 달성했습니다"),
        "pt-BR": (f"Sequência de {n} vitórias", f"Vença {n} partidas seguidas contra a CPU", f"Você venceu {n} partidas seguidas contra a CPU"),
        "zh-Hans": (f"{n}连胜", f"连续赢得{n}场电脑对局", f"已连续赢得{n}场电脑对局"),
    }[locale]


def wins_copy(value: int, locale: str) -> tuple[str, str, str]:
    n = number(value, locale)
    return {
        "ja": (f"通算{n}勝", f"CPU戦で通算{n}勝しよう", f"CPU戦で通算{n}勝した"),
        "en-US": (f"{n} Total Win{'s' if value != 1 else ''}", f"Win {n} CPU game{'s' if value != 1 else ''} in total.", f"Won {n} CPU game{'s' if value != 1 else ''} in total."),
        "es-ES": (f"{n} victoria{'s totales' if value != 1 else ' total'}", f"Consigue {n} victoria{'s' if value != 1 else ''} contra la CPU.", f"Conseguiste {n} victoria{'s' if value != 1 else ''} contra la CPU."),
        "fr": (f"{n} victoire{'s' if value != 1 else ''} au total", f"Remporte {n} victoire{'s' if value != 1 else ''} contre l'IA.", f"Tu as remporté {n} victoire{'s' if value != 1 else ''} contre l'IA."),
        "ko": (f"누적 {n}승", f"CPU 대전에서 누적 {n}승을 달성하세요.", f"CPU 대전에서 누적 {n}승을 달성했습니다."),
        "pt-BR": (f"{n} vitória{'s' if value != 1 else ''} no total", f"Consiga {n} vitória{'s' if value != 1 else ''} contra a CPU.", f"Você conseguiu {n} vitória{'s' if value != 1 else ''} contra a CPU."),
        "zh-Hans": (f"累计{n}胜", f"在电脑对战中累计获胜{n}场。", f"已在电脑对战中累计获胜{n}场。"),
    }[locale]


TWO_PLAYER_COPY = {
    "ja": ("友達100人できるかな", "同じ端末で2人対戦を101回終えよう", "同じ端末で2人対戦を101回終えた"),
    "en-US": ("101 Local Matches", "Finish 101 local two-player matches on the same device.", "Finished 101 local two-player matches on the same device."),
    "es-ES": ("101 partidas locales", "Termina 101 partidas locales de 2 jugadores en el mismo dispositivo.", "Terminaste 101 partidas locales de 2 jugadores en el mismo dispositivo."),
    "fr": ("101 parties en local", "Termine 101 parties à 2 sur le même appareil.", "Tu as terminé 101 parties à 2 sur le même appareil."),
    "ko": ("로컬 2인 대전 101회", "같은 기기에서 로컬 2인 대전을 101회 완료하세요.", "같은 기기에서 로컬 2인 대전을 101회 완료했습니다."),
    "pt-BR": ("101 partidas locais", "Conclua 101 partidas locais para 2 no mesmo aparelho.", "Você concluiu 101 partidas locais para 2 no mesmo aparelho."),
    "zh-Hans": ("本地双人对战101场", "在同一台设备上完成101场本地双人对战。", "已在同一台设备上完成101场本地双人对战。"),
}


def localized(name: str, before: str, after: str) -> dict[str, str]:
    return {
        "displayName": name,
        "beforeDescription": before,
        "afterDescription": after,
    }


achievements = []
for index, difficulty in enumerate(DIFFICULTIES):
    identifier = f"othello.cpu.{difficulty}"
    achievements.append({
        "identifier": identifier,
        "image": f"achievement-icons/{identifier}-v3.png",
        "localizations": {
            locale: localized(*DIFFICULTY_COPY[locale][index]) for locale in LOCALES
        },
    })
for value in STREAKS:
    identifier = f"othello.streak.{value}"
    achievements.append({
        "identifier": identifier,
        "image": f"achievement-icons/{identifier}-v3.png",
        "localizations": {locale: localized(*streak_copy(value, locale)) for locale in LOCALES},
    })
for value in WINS:
    identifier = f"othello.wins.{value}"
    achievements.append({
        "identifier": identifier,
        "image": f"achievement-icons/{identifier}-v3.png",
        "localizations": {locale: localized(*wins_copy(value, locale)) for locale in LOCALES},
    })
identifier = "othello.two_player.101"
achievements.append({
    "identifier": identifier,
    "image": f"achievement-icons/{identifier}-v3.png",
    "localizations": {locale: localized(*TWO_PLAYER_COPY[locale]) for locale in LOCALES},
})

assert len(achievements) == 20
assert len({item["identifier"] for item in achievements}) == 20
for item in achievements:
    assert (ROOT / item["image"]).is_file(), item["image"]
    assert set(item["localizations"]) == set(LOCALES)
    for locale, copy in item["localizations"].items():
        for field, limit in (("displayName", 30), ("beforeDescription", 120), ("afterDescription", 120)):
            value = copy[field]
            utf16_length = len(value.encode("utf-16-le")) // 2
            assert value and len(value) <= limit and utf16_length <= limit, (
                item["identifier"], locale, field, len(value), utf16_length
            )

payload = {
    "locales": list(LOCALES),
    "note": "Local two-player matches are completed games on one device; 101 completed matches unlock the achievement.",
    "achievements": achievements,
}
json_path = ROOT / "game-center-achievements-localized.json"
markdown_path = ROOT / "game-center-achievements-localized.md"
for path in (json_path, markdown_path):
    assert not path.exists(), f"Refusing to overwrite {path}"

json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
lines = [
    "# Game Center achievement localizations",
    "",
    "20 achievements × 7 locales. Names: 30 characters max; before and after descriptions: 120 characters max.",
    "Images use the circular `-v3.png` variants. Local two-player matches are completed games on one device.",
    "",
]
for locale in LOCALES:
    lines.extend([
        f"## {locale}",
        "",
        "| ID | Display name | Before achievement | After achievement | Image |",
        "| --- | --- | --- | --- | --- |",
    ])
    for item in achievements:
        copy = item["localizations"][locale]
        lines.append(
            f"| `{item['identifier']}` | {copy['displayName']} | {copy['beforeDescription']} | "
            f"{copy['afterDescription']} | `{item['image']}` |"
        )
    lines.append("")
markdown_path.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {json_path} and {markdown_path}; validated 140 localizations.")
