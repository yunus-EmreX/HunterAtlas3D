🏹 HunterAtlas3D
Anthropological Survival & Habitat Interaction Simulator

Built with Godot 4 (OpenGL Compatibility Renderer)

📌 Overview

HunterAtlas3D is an experimental simulation tool designed to model how different human hunting archetypes interact with diverse ecological environments.

Rather than being a traditional game, this project functions as a visual + systemic research sandbox exploring:

Environmental pressure on human physiology

Energy and hydration survival thresholds

Habitat-specific risk exposure

Behavioral adaptation advantages

Probabilistic hunting success across ecosystems

Short-term survival outcomes under dynamic conditions

It combines lightweight agent simulation with real-time environmental visualization to make abstract survival variables spatially understandable.

🌍 Modeled Environments

The simulator includes multiple ecological zones representing historically significant human habitats:

Biome	Modeled Strategy
Central Asian Steppe	Mobility-optimized hunter physiology
African Savanna	Persistence hunting adaptation
Boreal Taiga	Cold endurance foraging
Tropical Rainforest	Low-visibility tracking strategies
Arctic Tundra	High-calorie survival dependence
Temperate Forest	Mixed opportunistic subsistence
Northern Maritime Zones	Coastal hunting adaptation
Proto-Urban Mediterranean	Early hybrid survival behavior

Each biome alters metabolic cost, exposure risk, and resource availability.

🧠 Simulation Model

The system uses a time-stepped probabilistic model:

Energy Expenditure
Basal Metabolism
+ Locomotion Cost (terrain dependent)
+ Environmental Stress Load
− Cultural / Biological Adaptation Modifier
Hydration Drain
Activity × Wind Exposure × Humidity Gradient
Hunting Success Probability
Tracking Skill × Game Density × Habitat Familiarity
Mortality Risk Envelope
Fatigue + Injury + Starvation + Exposure → Survival Threshold

The goal is not deterministic realism, but to observe behavioral tendencies under ecological pressure.

🎨 Visualization Philosophy

HunterAtlas3D intentionally visualizes survival variables through minimalist diorama rendering:

Each biome dynamically recolors terrain to represent ecological tone.

Procedural environmental props (trees, stones, ruins, vegetation) appear per biome.

Ambient fog density reflects humidity and exposure.

Particle systems simulate rain or snowfall based on climate data.

Animal agents wander semi-randomly to represent resource availability.

Selected habitats visually “respond” rather than simply changing UI data.

This allows environmental differences to be perceived spatially rather than read numerically.

🎥 Camera & Interaction
Input	Action
Right Mouse Drag	Orbit camera
Mouse Wheel	Zoom
Biome Marker	Select environment
Run Simulation	Execute time model
⚙️ Technical Design Goals

This project deliberately prioritizes maximum hardware compatibility over graphical complexity.

✔ Runs on Integrated GPUs (Intel UHD tested)
✔ Uses gl_compatibility renderer — no Vulkan required
✔ Avoids advanced shaders / heavy materials
✔ Written to prevent Godot 4.x strict parser failures
✔ No type inference that triggers warning-as-error configurations

The architecture favors robustness and clarity rather than performance optimization.

📂 Project Structure
assets/        Visual resources
data/          JSON biome & hunter definitions
scenes/        Godot scene composition
scripts/       Simulation + behavior logic
➕ Adding a New Biome

Simply add a JSON file to:

data/biomes/

Example:

{
  "id": "desert",
  "name": "Arid Desert",
  "climate": { "temp_c_avg": 38, "humidity": 0.1, "wind": 0.6 },
  "resources": { "water": 0.2, "game": 0.3 },
  "hazards": { "predators": 0.2, "parasites": 0.1, "exposure": 0.9 }
}

No code modification required.

🚀 Running the Project

Download repository

Open Godot → Import → select project.godot

Press F5

🔬 Intended Use Cases

Anthropological modeling prototypes

Survival mechanics research

Environment-driven gameplay design studies

Educational visualization of ecological adaptation

Rapid sandbox for human-environment interaction theory

📜 License

MIT License — free to modify and extend.
