tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                    },
                    colors: {
                        brand: {
                            50: '#f0fdfa',
                            100: '#ccfbf1',
                            500: '#14b8a6', // Teal
                            600: '#0d9488',
                            900: '#134e4a',
                        },
                        accent: {
                            500: '#8b5cf6', // Violet
                        }
                    }
                }
            }
        }
document.addEventListener('DOMContentLoaded', () => {
            // Lógica para animaciones de entrada (fade-in-up) al hacer scroll
            const observerOptions = {
                root: null,
                rootMargin: '0px',
                threshold: 0.15 // El elemento aparece cuando el 15% es visible
            };

            const observer = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('visible');
                        observer.unobserve(entry.target); // Solo animar la primera vez
                    }
                });
            }, observerOptions);

            const fadeElements = document.querySelectorAll('.fade-in-up');
            fadeElements.forEach(el => {
                observer.observe(el);
            });

            // Lógica simple para manejar los botones de las tiendas de apps (Alertas personalizadas ya que son placeholders)
            const appLinks = document.querySelectorAll('a[href="#"]');
            appLinks.forEach(link => {
                link.addEventListener('click', (e) => {
                    e.preventDefault();
                    // Simulamos un tooltip temporal o notificación en lugar de alert()
                    const originalHTML = link.innerHTML;
                    link.innerHTML = '<div class="text-center w-full font-semibold">¡Próximamente!</div>';
                    setTimeout(() => {
                        link.innerHTML = originalHTML;
                    }, 2000);
                });
            });
        });