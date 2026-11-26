"""Builds mod/LiberateSpell.esp (dialogue + token item) for the Liberate Spell mod.

Run:  python tools/build_esp.py [path-to-Morrowind.esm]
The master path is only used to record Morrowind.esm's file size in the header.
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'mod', 'LiberateSpell.esp')
DEFAULT_MASTER = r'D:\Steam\steamapps\common\Morrowind\Data Files\Morrowind.esm'

TOKEN = 'liberate_token'
CHOICE_FREE = 71
CHOICE_WAIT = 72

# First vanilla INFO in each dialogue; our entries are linked in front of them.
VANILLA_HEAD = {
    'go free': '199641425381905494',
    'Greeting 0': '1224319899288117550',
}


def zstr(s):
    return s.encode('cp1252') + b'\x00'


def sub(name, data):
    return name.encode('ascii') + struct.pack('<i', len(data)) + data


def record(name, subs):
    body = b''.join(subs)
    return name.encode('ascii') + struct.pack('<iii', len(body), 0, 0) + body


# --- dialogue conditions -------------------------------------------------
COMP = {'==': '0', '!=': '1', '>': '2', '>=': '3', '<': '4', '<=': '5'}


def cond_local(var, op, value):
    return ('3', 'sX', op, var, value)


def cond_item(item, op, value):
    return ('5', 'IX', op, item, value)


def cond_choice(value):
    return ('1', '50', '==', '', value)


def conditions(conds):
    out = []
    for i, (kind, func, op, name, value) in enumerate(conds):
        text = f'{i}{kind}{func}{COMP[op]}{name}'
        out.append(sub('SCVR', text.encode('ascii')))
        out.append(sub('INTV', struct.pack('<i', value)))
    return out


DIAL_TYPE = {'topic': 0, 'greeting': 2}


def info(info_id, prev_id, next_id, dial_type, text, conds, result=None, race=None):
    data = struct.pack('<ii', DIAL_TYPE[dial_type], 0) + bytes([0xFF, 0xFF, 0xFF, 0x00])
    subs = [
        sub('INAM', zstr(info_id)),
        sub('PNAM', zstr(prev_id)),
        sub('NNAM', zstr(next_id)),
        sub('DATA', data),
    ]
    if race:
        subs.append(sub('RNAM', zstr(race)))
    subs.append(sub('NAME', text.encode('cp1252')))
    subs += conditions(conds)
    if result:
        subs.append(sub('BNAM', '\r\n'.join(result).encode('cp1252')))
    return record('INFO', subs)


def dialogue(name, dial_type, entries):
    """entries: list of dicts with keys text, conds, result, race (optional)."""
    recs = [record('DIAL', [sub('NAME', zstr(name)), sub('DATA', bytes([DIAL_TYPE[dial_type]]))])]
    prefix = 'LiberateSpell_' + ('G' if dial_type == 'greeting' else 'T')
    ids = [f'{prefix}{i + 1:02d}' for i in range(len(entries))]
    for i, e in enumerate(entries):
        prev_id = ids[i - 1] if i > 0 else ''
        next_id = ids[i + 1] if i + 1 < len(entries) else VANILLA_HEAD[name]
        recs.append(info(ids[i], prev_id, next_id, dial_type, e['text'], e['conds'],
                         e.get('result'), e.get('race')))
    return recs


# --- content -------------------------------------------------------------
UNFREED = cond_local('slaveStatus', '<', 3)
HAS_TOKEN = cond_item(TOKEN, '>=', 1)

FREE_RESULT = [
    'Set slaveStatus to 3',
    'Set FreedSlavesCounter to FreedSlavesCounter + 1',
    'ModDisposition 50',
    f'Player->RemoveItem "{TOKEN}" 1',
    'PlaySound "alteration hit"',
]

GREETINGS = [
    {
        'race': 'Khajiit',
        'text': "Your magic... %Name can feel it on these bracers! Will you let %Name go free?",
        'conds': [UNFREED, HAS_TOKEN],
        'result': ['AddTopic "go free"'],
    },
    {
        'text': "Your magic... I can feel it working on these bracers! Will you let me go free?",
        'conds': [UNFREED, HAS_TOKEN],
        'result': ['AddTopic "go free"'],
    },
]

GO_FREE = [
    {
        'race': 'Khajiit',
        'text': "The bracers fall away! %Name is free! Thank you, %PCName. Khajiit will not forget this.",
        'conds': [cond_choice(CHOICE_FREE), UNFREED],
        'result': FREE_RESULT,
    },
    {
        'text': "The bracers fall away! I'm free! Thank you, %PCName. I will never forget this.",
        'conds': [cond_choice(CHOICE_FREE), UNFREED],
        'result': FREE_RESULT,
    },
    {
        'text': "Please, don't wait too long. I don't think your spell will last.",
        'conds': [cond_choice(CHOICE_WAIT), UNFREED],
    },
    {
        'text': "Your spell has weakened the enchantment on these bracers. Will you set me free?",
        'conds': [UNFREED, HAS_TOKEN],
        'result': [f'Choice "Break the bracers\' enchantment." {CHOICE_FREE} "Not yet." {CHOICE_WAIT}'],
    },
]


def token_item():
    return record('MISC', [
        sub('NAME', zstr(TOKEN)),
        sub('MODL', zstr(r'm\Key_Standard_01.NIF')),
        sub('FNAM', zstr('Liberate (spell effect)')),
        sub('MCDT', struct.pack('<fii', 0.0, 0, 0)),
        sub('ITEX', zstr(r'm\Tx_key_standard_01.tga')),
    ])


def header(num_records, master_size):
    author = 'MVXK21'.encode('ascii').ljust(32, b'\x00')
    desc = ('Cast Liberate on a slave to unlock the "go free" choice without the key. '
            'Requires LiberateSpell.omwscripts.').encode('ascii').ljust(256, b'\x00')
    hedr = struct.pack('<fi', 1.3, 0) + author + desc + struct.pack('<i', num_records)
    return record('TES3', [
        sub('HEDR', hedr),
        sub('MAST', zstr('Morrowind.esm')),
        sub('DATA', struct.pack('<q', master_size)),
    ])


def main():
    master = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MASTER
    master_size = os.path.getsize(master) if os.path.exists(master) else 79837557
    recs = [token_item()]
    recs += dialogue('Greeting 0', 'greeting', GREETINGS)
    recs += dialogue('go free', 'topic', GO_FREE)
    data = header(len(recs), master_size) + b''.join(recs)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'wb') as f:
        f.write(data)
    print(f'Wrote {os.path.normpath(OUT)} ({len(recs)} records, {len(data)} bytes)')


if __name__ == '__main__':
    main()
