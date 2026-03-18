"""
Generate assets/airports.json from OurAirports open data.

Usage:
  curl -o /tmp/airports.csv https://davidmegginson.github.io/ourairports-data/airports.csv
  python scripts/generate_airports.py /tmp/airports.csv
"""
import csv, json, sys

source = sys.argv[1] if len(sys.argv) > 1 else '/tmp/airports.csv'
result = []
with open(source, encoding='utf-8') as f:
    for row in csv.DictReader(f):
        if row['type'] not in ('large_airport', 'medium_airport'):
            continue
        iata = row['iata_code'].strip().upper()
        if not iata:
            continue
        try:
            result.append({
                'iata': iata,
                'name': row['name'].strip(),
                'city': row['municipality'].strip(),
                'country': row['iso_country'].strip(),
                'lat': float(row['latitude_deg']),
                'lon': float(row['longitude_deg']),
            })
        except (ValueError, KeyError):
            continue

result.sort(key=lambda a: a['iata'])
out = 'assets/airports.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, separators=(',', ':'))
print(f'Wrote {len(result)} airports to {out}')
