const stack = document.getElementById('notifications');

const TITLES = {
    success: 'Done',
    error: 'Problem',
    warning: 'Careful',
    info: 'Notice',
};

const ICONS = {
    success: '✓',
    error: '✕',
    warning: '!',
    info: 'i',
};

const esc = (s) => String(s ?? '').replace(/[&<>"']/g,
    c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

let position = 'top-right';
let max = 4;

function show({ text, type = 'info', title, duration = 4000 }) {
    if (!text) return;
    if (!TITLES[type]) type = 'info';

    // Oldest goes first when they pile up - a wall of notifications is
    // worse than missing the one you already read.
    while (stack.children.length >= max) stack.firstElementChild.remove();

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
        <span class="icon">${ICONS[type]}</span>
        <div class="body">
            <div class="title">${esc(title || TITLES[type])}</div>
            <div class="text">${esc(text)}</div>
        </div>
        <div class="timer" style="animation-duration:${duration}ms"></div>`;

    stack.appendChild(toast);

    setTimeout(() => {
        toast.classList.add('out');
        setTimeout(() => toast.remove(), 240);
    }, duration);
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'notify') return show(data);

    if (data.action === 'config') {
        if (data.position) {
            position = data.position;
            stack.className = `stack ${position}`;
        }
        if (data.max) max = data.max;
    }
});

stack.className = `stack ${position}`;
