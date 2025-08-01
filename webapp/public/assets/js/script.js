function calculateAge(birthDate) {
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    const dayDiff = today.getDate() - birthDate.getDate();

    // If birthday hasn't occurred yet this year, subtract 1
    if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
        age--;
    }
    return age;
}

const birthDate = new Date('2003-06-18');
const age = calculateAge(birthDate);
document.getElementById('age').textContent = age;

const images = [
    {
        src: './assets/images/Norway/IMG_1655.jpg',
        alt: 'Lake'
    },
    {
        src: './assets/images/Norway/IMG_1651.jpg',
        alt: 'Lake with bench'
    },
    {
        src: './assets/images/Norway/IMG_1687.jpg',
        alt: 'Mountain with Pole'
    },
    {
        src: './assets/images/Norway/IMG_3773.jpg',
        alt: 'Top of Mountain'
    },
    {
        src: './assets/images/Norway/IMG_7702.jpg',
        alt: 'SHEEEEP'
    }
];

let currentIndex = 0;

const aboutImage = document.getElementById('aboutImage');
const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');

function updateImage() {
    aboutImage.src = images[currentIndex].src;
    aboutImage.alt = images[currentIndex].alt;
}

prevBtn.addEventListener('click', () => {
    currentIndex = (currentIndex - 1 + images.length) % images.length;
    updateImage();
});

nextBtn.addEventListener('click', () => {
    currentIndex = (currentIndex + 1) % images.length;
    updateImage();
});