---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.
license: Apache-2.0 — full terms in LICENSE.txt
---

# Frontend Design

**Version:** v1.0.0 (vendored)

This skill guides creation of distinctive, production-grade frontend
interfaces that avoid generic "AI slop" aesthetics. Implement real working
code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or
interface to build. They may include context about the purpose, audience,
or technical constraints.

## Source & updates

Vendored from Anthropic's public skills repo (Apache-2.0). To check for or
pull upstream changes, see `SOURCE.md` in this directory.

- Upstream: `anthropics/skills`, path `skills/frontend-design`
- Vendored at commit `0075614` (2025-12-04)

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic
direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-
  futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/
  magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/
  utilitarian, etc. There are so many flavors to choose from. Use these for
  inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance,
  accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing
  someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with
precision. Bold maximalism and refined minimalism both work — the key is
intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:

- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:

- **Typography**: Choose fonts that are beautiful, unique, and interesting.
  Avoid generic fonts like Arial and Inter; opt instead for distinctive
  choices that elevate the frontend's aesthetics — unexpected, characterful
  font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for
  consistency. Dominant colors with sharp accents outperform timid, evenly-
  distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize
  CSS-only solutions for HTML. Use a motion library for React only when one
  is genuinely warranted (see *Fit with this environment*). Focus on high-
  impact moments: one well-orchestrated page load with staggered reveals
  (animation-delay) creates more delight than scattered micro-interactions.
  Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal
  flow. Grid-breaking elements. Generous negative space OR controlled
  density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than
  defaulting to solid colors. Add contextual effects and textures that match
  the overall aesthetic. Apply creative forms like gradient meshes, noise
  textures, geometric patterns, layered transparencies, dramatic shadows,
  decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families
(Inter, Roboto, Arial, system fonts), clichéd color schemes (particularly
purple gradients on white backgrounds), predictable layouts and component
patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely
designed for the context. No design should be the same. Vary between light
and dark themes, different fonts, different aesthetics. NEVER converge on
common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision.
Maximalist designs need elaborate code with extensive animations and
effects. Minimalist or refined designs need restraint, precision, and
careful attention to spacing, typography, and subtle details. Elegance
comes from executing the vision well.

Remember: extraordinary creative work is the goal. Don't hold back — show
what can truly be created when thinking outside the box and committing
fully to a distinctive vision.

## Fit with this environment

The creative guidance above is the heart of the skill; honour it. But the
*how* must obey the repo's own rules when they apply (rules are detection-
based, so they only bind when the relevant tool is present). Defer to:

- **React + TypeScript** — function components, typed props, no `any`; see
  `rules/react.md` and `rules/typescript.md`.
- **Biome, not Prettier/ESLint** — format and lint with Biome; `tsc` owns
  type-checking. After any `*.ts`/`*.tsx`/`*.css` change run
  `biome check --write` (or `npm run format`) then `tsc`. See
  `rules/biome.md`.
- **Plain CSS conventions** — define color/spacing **tokens as `:root`
  custom properties** and reference them; keep specificity low and flat;
  comment the *why* of magic numbers. This aligns with the skill's "use CSS
  variables." See `rules/css.md`.
- **Component library (Mantine), if present** — use it for app *chrome*
  (shell, nav, inputs) and its theme tokens; reserve bespoke CSS for the
  content surfaces this skill makes distinctive. See `rules/mantine.md`.
- **Markdown/comments wrap at 78/72 columns**, intent-revealing names,
  paragraph spacing — see `rules/code-style.md`.

**Bundle discipline (overrides the upstream "use a motion library"
default).** Do not add a motion/animation dependency (Motion / framer-
motion, GSAP, etc.) prophylactically. Prefer CSS-only animation. If a React
motion library is genuinely needed, first surface its gzip bundle cost
(per `rules/mantine.md`) and add a `rules/<lib>.md` for it (per the
rule-coverage convention in `CLAUDE.md`) before introducing it.

After UI changes, build (`npm run build`) to confirm types and bundle size.
