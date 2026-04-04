import { useEffect, useLayoutEffect, useRef, useState } from 'react';

const slides = [
  {
    title: 'Sign In',
    description: 'A clean entry screen for students to access the portal quickly.',
    src: '/assets/student-mockups/01-sign-in.png'
  },
  {
    title: 'Signup',
    description: 'Account creation with a mobile-friendly onboarding flow.',
    src: '/assets/student-mockups/02-signup.png'
  },
  {
    title: 'Forgot Password',
    description: 'A simple recovery path when students need account access again.',
    src: '/assets/student-mockups/03-forgot-password.png'
  },
  {
    title: 'Dashboard',
    description: 'The central overview for alerts, updates, and next actions.',
    src: '/assets/student-mockups/04-dashboard.png'
  },
  {
    title: 'Profile',
    description: 'Profile completion and student information management.',
    src: '/assets/student-mockups/05-profile.png'
  },
  {
    title: 'Jobs',
    description: 'Browse available opportunities and open roles.',
    src: '/assets/student-mockups/06-jobs.png'
  },
  {
    title: 'Requests',
    description: 'Track interview and company interaction requests.',
    src: '/assets/student-mockups/07-requests.png'
  },
  {
    title: 'Settings',
    description: 'User preferences and app configuration in one place.',
    src: '/assets/student-mockups/08-settings.png'
  },
  {
    title: 'Companies',
    description: 'Explore companies participating in the job fair.',
    src: '/assets/student-mockups/09-companies.png'
  }
];

export function StudentMockupSlider() {
  const [trackIndex, setTrackIndex] = useState(slides.length);
  const [activeIndex, setActiveIndex] = useState(0);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const slideRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const stepRef = useRef(0);
  const copyWidthRef = useRef(0);
  const loopedSlides = [...slides, ...slides, ...slides];
  const middleStart = slides.length;
  const middleEnd = slides.length * 2;

  useEffect(() => {
    const timer = window.setInterval(() => {
      setTrackIndex((current) => current + 1);
    }, 4500);

    return () => window.clearInterval(timer);
  }, []);

  useLayoutEffect(() => {
    const first = slideRefs.current[middleStart];
    const second = slideRefs.current[middleStart + 1];

    if (!first || !second) {
      return;
    }

    stepRef.current = second.offsetLeft - first.offsetLeft;
    copyWidthRef.current = stepRef.current * slides.length;
  }, [middleStart]);

  useLayoutEffect(() => {
    const container = containerRef.current;
    const target = slideRefs.current[trackIndex];

    if (!container || !target || !stepRef.current || !copyWidthRef.current) {
      return;
    }

    if (trackIndex >= middleEnd) {
      setTrackIndex((current) => current - slides.length);
      container.scrollLeft -= copyWidthRef.current;
      return;
    }

    if (trackIndex < middleStart) {
      setTrackIndex((current) => current + slides.length);
      container.scrollLeft += copyWidthRef.current;
      return;
    }

    const nextActiveIndex = trackIndex % slides.length;
    setActiveIndex(nextActiveIndex);
    const centeredLeft = target.offsetLeft - (container.clientWidth - target.clientWidth) / 2;
    container.scrollTo({
      left: centeredLeft,
      behavior: 'smooth'
    });
  }, [trackIndex, middleEnd, middleStart]);

  const goToSlide = (index: number) => {
    setTrackIndex(slides.length + index);
  };

  return (
    <section className="relative left-1/2 w-screen -translate-x-1/2 bg-white py-6 sm:py-8">
      <div ref={containerRef} className="overflow-x-auto overflow-y-visible [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <div className="pointer-events-none absolute inset-y-0 left-0 z-10 w-12 bg-gradient-to-r from-white to-transparent sm:w-20" />
        <div className="pointer-events-none absolute inset-y-0 right-0 z-10 w-12 bg-gradient-to-l from-white to-transparent sm:w-20" />

        <div className="flex min-w-max items-center justify-center gap-3 px-6 sm:gap-4 lg:gap-5">
          {loopedSlides.map((slide, index) => {
            const isActive = index === trackIndex;
            const distance = Math.abs(index - trackIndex);
            const wrappedDistance = Math.min(distance, loopedSlides.length - distance);
            const isNearActive = wrappedDistance === 1;

            return (
              <button
                key={`${slide.src}-${index}`}
                ref={(element) => {
                  slideRefs.current[index] = element;
                }}
                type="button"
                onClick={() => goToSlide(index % slides.length)}
                className="flex-shrink-0"
              >
                <div className={`w-[116px] sm:w-[148px] md:w-[164px] ${isActive ? 'z-10' : ''}`}>
                  <div className={`overflow-hidden rounded-[1.9rem] bg-white p-1.5 shadow-none transition-transform duration-300 aspect-[3/5] ${isActive ? 'scale-[1.1]' : isNearActive ? 'scale-[0.95]' : 'scale-[0.85]'}`}>
                    <img
                      src={slide.src}
                      alt={slide.title}
                      className="block h-full w-full rounded-[1.3rem] object-contain"
                      loading="lazy"
                    />
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </section>
  );
}
