document.addEventListener('DOMContentLoaded', () => {
    const cmdKey = document.getElementById('cmd-key');
    const shiftKey = document.getElementById('shift-key');
    const nKey = document.getElementById('n-key');
    const wKey = document.getElementById('w-key');
    const aKey = document.getElementById('a-key');
    const sKey = document.getElementById('s-key');
    const screenBody = document.getElementById('screen-body');

    let modifiers = {
        command: false,
        shift: false
    };

    // Toggle Modifiers
    cmdKey.addEventListener('click', () => {
        modifiers.command = !modifiers.command;
        cmdKey.classList.toggle('active', modifiers.command);
    });

    shiftKey.addEventListener('click', () => {
        modifiers.shift = !modifiers.shift;
        shiftKey.classList.toggle('active', modifiers.shift);
    });

    // Key actions
    nKey.addEventListener('click', () => {
        triggerKey(nKey);
        if (modifiers.command && !modifiers.shift) {
            spawnNote();
        } else {
            showPrompt("To create a note, activate ⌘ and press N");
        }
    });

    wKey.addEventListener('click', () => {
        triggerKey(wKey);
        if (modifiers.command && !modifiers.shift) {
            closeFrontmostNote();
        } else {
            showPrompt("To close a note, activate ⌘ and press W");
        }
    });

    sKey.addEventListener('click', () => {
        triggerKey(sKey);
        if (modifiers.command && !modifiers.shift) {
            triggerSaveAnimation();
        } else {
            showPrompt("To save notes, activate ⌘ and press S");
        }
    });

    aKey.addEventListener('click', () => {
        triggerKey(aKey);
        if (modifiers.command && modifiers.shift) {
            showAllNotes();
        } else {
            showPrompt("To show all notes, activate ⌘ + ⇧ and press A");
        }
    });

    function triggerKey(keyEl) {
        keyEl.classList.add('active');
        setTimeout(() => {
            keyEl.classList.remove('active');
        }, 150);
    }

    function showPrompt(text) {
        clearPlaceholder();
        const msg = document.createElement('div');
        msg.className = 'simulator-message';
        msg.textContent = text;
        msg.style.position = 'absolute';
        msg.style.bottom = '10px';
        msg.style.fontSize = '11px';
        msg.style.color = '#3b82f6';
        msg.style.background = 'rgba(59, 130, 246, 0.1)';
        msg.style.padding = '4px 10px';
        msg.style.borderRadius = '20px';
        msg.style.border = '1px solid rgba(59, 130, 246, 0.2)';
        msg.style.animation = 'fadeOut 3s forwards';
        screenBody.appendChild(msg);
        setTimeout(() => msg.remove(), 3000);
    }

    function clearPlaceholder() {
        const placeholder = screenBody.querySelector('.placeholder-text');
        if (placeholder) placeholder.remove();
    }

    let noteCount = 0;

    function spawnNote() {
        clearPlaceholder();
        noteCount++;
        const note = document.createElement('div');
        note.className = 'simulated-note';
        note.id = `sim-note-${noteCount}`;
        
        // Random pastel color hexes
        const colors = ['#FFF9A6', '#FFC5D9', '#BCE2FF', '#BFFCC6'];
        const randomColor = colors[Math.floor(Math.random() * colors.length)];
        
        // Random offset positions inside preview screen
        const randomX = Math.floor(Math.random() * 40) + 10;
        const randomY = Math.floor(Math.random() * 30) + 10;

        note.innerHTML = `
            <div class="sim-note-header">
                <span class="sim-note-title">Note #${noteCount}</span>
                <span class="sim-note-close">×</span>
            </div>
            <div class="sim-note-body">
                Editable content floating on your desktop...
            </div>
        `;

        note.style.position = 'absolute';
        note.style.width = '120px';
        note.style.background = randomColor;
        note.style.color = '#111827';
        note.style.borderRadius = '6px';
        note.style.padding = '6px';
        note.style.fontSize = '9px';
        note.style.boxShadow = '0 6px 12px rgba(0,0,0,0.3)';
        note.style.left = `${randomX}%`;
        note.style.top = `${randomY}%`;
        note.style.cursor = 'move';
        note.style.transition = 'opacity 0.3s ease, transform 0.2s ease';

        // Close on visual close tap
        note.querySelector('.sim-note-close').addEventListener('click', () => {
            note.remove();
            checkEmpty();
        });

        screenBody.appendChild(note);
    }

    function closeFrontmostNote() {
        const notes = screenBody.querySelectorAll('.simulated-note');
        if (notes.length > 0) {
            notes[notes.length - 1].remove();
        }
        checkEmpty();
    }

    function triggerSaveAnimation() {
        const notes = screenBody.querySelectorAll('.simulated-note');
        if (notes.length === 0) {
            showPrompt("No notes to save! Spawn a note first.");
            return;
        }
        notes.forEach(note => {
            note.style.transform = 'scale(1.05)';
            setTimeout(() => {
                note.style.transform = 'scale(1)';
            }, 200);
        });
        showPrompt("Notes Saved Successfully to Local Storage! 💾");
    }

    function showAllNotes() {
        const notes = screenBody.querySelectorAll('.simulated-note');
        if (notes.length === 0) {
            showPrompt("No notes available. Press ⌘ + N to spawn notes.");
            return;
        }
        notes.forEach(note => {
            note.style.opacity = '1';
        });
        showPrompt("Revealed all notes! 👁️");
    }

    function checkEmpty() {
        const notes = screenBody.querySelectorAll('.simulated-note');
        if (notes.length === 0) {
            screenBody.innerHTML = '<div class="placeholder-text">Press a hotkey combination above to test (e.g. ⌘ + N)</div>';
        }
    }
});
