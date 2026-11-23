// Lab 3 — js/main.js
// One file serves all six pages. Each block runs only where its
// elements exist, so every listener and every block is guarded.
// Linked in the head of every page as:
//   <script src="js/main.js" defer></script>
// defer: download now, run only after the whole page has been read,
// so every element exists when the script looks for it.

// ---- 1. deliveries.html: litres, checked as typed
const litres = document.querySelector('#litres');
const litresMessage = document.querySelector('#litres-message');

function checkLitres() {
  const amount = Number(litres.value);
  if (litres.value === '') {
    litresMessage.textContent = '';
    litres.classList.remove('invalid');
  } else if (amount <= 0) {
    litresMessage.textContent = 'Litres must be more than 0.';
    litres.classList.add('invalid');
  } else if (amount > 60) {
    litresMessage.textContent = 'Over 60 litres in one session. Check the reading.';
    litres.classList.add('invalid');
  } else {
    litresMessage.textContent = '';
    litres.classList.remove('invalid');
  }
}

if (litres) {
  litres.addEventListener('input', checkLitres);
}

// ---- 2. deliveries.html: member number, checked on blur
const member = document.querySelector('#member');
const memberMessage = document.querySelector('#member-message');

function checkMember() {
  if (!member) {
    return;
  }

  const value = member.value.trim();
  if (value === '') {
    memberMessage.textContent = '';
    member.classList.remove('invalid');
    return;
  }

  if (/^ER-[0-9]{4}$/.test(value)) {
    memberMessage.textContent = '';
    member.classList.remove('invalid');
  } else {
    memberMessage.textContent = 'A member number looks like ER-0001.';
    member.classList.add('invalid');
  }
}

if (member) {
  member.addEventListener('blur', checkMember);
}

// ---- 3. deliveries.html: form, checked on submit
const deliveryForm = document.querySelector('#delivery-form');

function recordDelivery(event) {
  checkMember();
  checkLitres();

  if (member.classList.contains('invalid')) {
    event.preventDefault(); // stop: the member number is wrong
    member.focus();
  } else if (litres.classList.contains('invalid')) {
    event.preventDefault(); // stop: the litres are wrong
    litres.focus();
  }
  // nothing wrong: the form goes on to process-delivery.php
}

if (deliveryForm) {
  deliveryForm.addEventListener('submit', recordDelivery);
}

// ---- 4. index.html: the three numbers move
const statValues = document.querySelectorAll('.stat strong');

if (statValues.length === 3) {
  const targets = [474, 16, 312];
  const duration = 900;
  const startedAt = performance.now();

  function step(now) {
    const done = Math.min((now - startedAt) / duration, 1);

    for (let i = 0; i < 3; i++) {
      statValues[i].textContent = Math.round(targets[i] * done);
    }

    if (done < 1) {
      requestAnimationFrame(step);
    }
  }

  requestAnimationFrame(step);
}

// ---- 5. deliveries.html: add up the accepted litres
const totalCell = document.querySelector('#accepted-total');

if (totalCell) {
  const rows = document.querySelectorAll('tbody tr');
  let total = 0;
  for (const row of rows) {
    const cells = row.querySelectorAll('td');
    if (cells.length > 4 && cells[4].textContent === 'Yes') {
      total = total + Number(cells[3].textContent);
    }
  }
  totalCell.textContent = total.toFixed(2);
}

// ---- 6. about.html: the year always current
const year = document.querySelector('#year');

if (year) {
  year.textContent = new Date().getFullYear();
}
