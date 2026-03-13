const sectionLinks = Array.from(document.querySelectorAll("[data-section-link]"));
const sections = Array.from(document.querySelectorAll("[data-section]"));
const revealTargets = Array.from(document.querySelectorAll("[data-reveal]"));
const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const setActiveSection = (activeId) => {
  sectionLinks.forEach((link) => {
    const isActive = link.getAttribute("href") === `#${activeId}`;
    link.classList.toggle("is-active", isActive);
  });
};

const sectionObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) {
        return;
      }

      setActiveSection(entry.target.getAttribute("id"));
    });
  },
  {
    rootMargin: "-35% 0px -45% 0px",
    threshold: 0.1,
  },
);

sections.forEach((section) => {
  sectionObserver.observe(section);
});

const revealObserver = prefersReducedMotion.matches
  ? null
  : new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) {
            return;
          }

          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      },
      {
        rootMargin: "0px 0px -8% 0px",
        threshold: 0.2,
      },
    );

revealTargets.forEach((target, index) => {
  target.style.transitionDelay = `${Math.min(index * 30, 120)}ms`;
  if (prefersReducedMotion.matches) {
    target.classList.add("is-visible");
    return;
  }

  revealObserver.observe(target);
});

const updateScrollEffects = () => {
  const viewportHeight = window.innerHeight;

  sections.forEach((section) => {
    const rect = section.getBoundingClientRect();
    const progress = clamp(
      (viewportHeight - rect.top) / (rect.height + viewportHeight),
      0,
      1,
    );

    section.style.setProperty("--section-progress", progress.toFixed(3));
  });

  if (prefersReducedMotion.matches) {
    return;
  }
};

let isTicking = false;

const requestScrollUpdate = () => {
  if (isTicking) {
    return;
  }

  isTicking = true;

  window.requestAnimationFrame(() => {
    updateScrollEffects();
    isTicking = false;
  });
};

window.addEventListener("scroll", requestScrollUpdate, { passive: true });
window.addEventListener("resize", requestScrollUpdate);

setActiveSection("hero");
updateScrollEffects();
