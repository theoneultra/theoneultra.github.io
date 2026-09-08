(() => {
  'use strict';
  const carousel = document.querySelector('[data-carousel]');
  if (!carousel) return;
  const slides = [...carousel.querySelectorAll('[data-slide]')];
  if (slides.length < 2) return;
  const dots = [...carousel.querySelectorAll('[data-slide-to]')];
  const counter = carousel.querySelector('[data-slide-current]');
  const pauseButton = carousel.querySelector('[data-carousel-pause]');
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const configuredInterval = Number(carousel.dataset.interval);
  const interval = Number.isFinite(configuredInterval) && configuredInterval >= 1000 ? configuredInterval : 5000;
  let current = 0;
  let timer;
  let animations = [];
  let transitionVersion = 0;
  let paused = motion.matches;
  let hovering = false;
  let touchX = null;
  let touchY = null;

  function schedule() {
    window.clearInterval(timer);
    if (paused || hovering || document.hidden || carousel.contains(document.activeElement)) return;
    timer = window.setInterval(() => show(current + 1), interval);
  }
  function show(index) {
    const target = (index + slides.length) % slides.length;
    if (target === current) return;
    const direction = index > current ? 1 : -1;
    const version = ++transitionVersion;
    animations.forEach(animation => animation.cancel());
    animations = [];
    slides.forEach((slide, i) => { slide.hidden = i !== current; });
    const outgoing = slides[current];
    const links = [...slides[current].querySelectorAll('a')];
    const focusedLink = links.indexOf(document.activeElement);
    current = target;
    const incoming = slides[current];
    incoming.hidden = false;
    incoming.inert = false;
    incoming.removeAttribute('aria-hidden');
    if (focusedLink !== -1) {
      const nextLinks = incoming.querySelectorAll('a');
      (nextLinks[focusedLink] || nextLinks[0])?.focus({ preventScroll: true });
    }
    slides.forEach((slide, i) => {
      slide.classList.toggle('is-active', i === current);
      slide.inert = i !== current;
      if (i !== current) slide.setAttribute('aria-hidden', 'true');
    });
    dots.forEach((dot, i) => dot.setAttribute('aria-pressed', String(i === current)));
    counter.textContent = String(current + 1).padStart(2, '0');
    if (motion.matches || typeof incoming.animate !== 'function') {
      outgoing.hidden = true;
      return;
    }
    const timing = { duration: 550, easing: 'cubic-bezier(0.22, 0.61, 0.36, 1)' };
    animations = [
      outgoing.animate([{ transform: 'translateX(0)' }, { transform: `translateX(${-direction * 100}%)` }], timing),
      incoming.animate([{ transform: `translateX(${direction * 100}%)` }, { transform: 'translateX(0)' }], timing)
    ];
    Promise.allSettled(animations.map(animation => animation.finished)).then(() => {
      if (version !== transitionVersion) return;
      slides.forEach((slide, i) => { slide.hidden = i !== current; });
      animations = [];
    });
  }
  function updatePause() {
    pauseButton.textContent = paused ? '▷' : 'Ⅱ';
    pauseButton.setAttribute('aria-label', paused ? '开始自动轮播' : '暂停自动轮播');
    schedule();
  }
  function navigate(index) { show(index); schedule(); }
  carousel.querySelector('[data-carousel-prev]').addEventListener('click', () => navigate(current - 1));
  carousel.querySelector('[data-carousel-next]').addEventListener('click', () => navigate(current + 1));
  dots.forEach((dot, index) => dot.addEventListener('click', () => navigate(index)));
  pauseButton.addEventListener('click', () => { paused = !paused; updatePause(); });
  carousel.addEventListener('mouseenter', () => { hovering = true; schedule(); });
  carousel.addEventListener('mouseleave', () => { hovering = false; schedule(); });
  carousel.addEventListener('focusin', schedule);
  carousel.addEventListener('focusout', () => window.setTimeout(schedule, 0));
  document.addEventListener('visibilitychange', schedule);
  motion.addEventListener('change', () => { paused = motion.matches; updatePause(); });
  carousel.addEventListener('keydown', event => {
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      event.preventDefault();
      navigate(current + (event.key === 'ArrowRight' ? 1 : -1));
    }
  });
  carousel.addEventListener('touchstart', event => {
    touchX = event.changedTouches[0].clientX;
    touchY = event.changedTouches[0].clientY;
  }, { passive: true });
  carousel.addEventListener('touchend', event => {
    if (touchX === null) return;
    const dx = event.changedTouches[0].clientX - touchX;
    const dy = event.changedTouches[0].clientY - touchY;
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) navigate(current + (dx < 0 ? 1 : -1));
    touchX = touchY = null;
  }, { passive: true });
  updatePause();
})();
