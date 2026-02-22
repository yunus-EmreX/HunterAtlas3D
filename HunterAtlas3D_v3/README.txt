HunterAtlas3D v2 (Godot 4.6.x, Intel UHD uyumlu)

- rendering_method = gl_compatibility
- warnings_as_errors = false
- Scriptlerde type inference (:=) kullanılmadı, Variant-safe yazıldı.

Kontroller
- Sağ mouse basılı sürükle: kamerayı döndür
- Mouse wheel: zoom
- Marker tıkla: biyom değişir (diorama + atmosfer + hayvanlar değişir)
- Simülasyonu Çalıştır: olayları loglar (Avlandı: <hayvan>)

Import:
Godot Project Manager -> Import -> project.godot
Sonra F5.


v3 düzeltmeleri:
- SphereShape3D fix
- WeatherParticles.process_material sub_resource fix
- Animal.init param adı rng_seed (seed uyarısı kalkar)
