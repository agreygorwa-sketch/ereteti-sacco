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
const memberShape = /^ER-[0-9]{4}$/; // a pattern: already a RegExp

function checkMember() {
  const typed = member.value.trim().toUpperCase();
  member.value = typed;

  if (memberShape.test(typed)) {
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

// ---- 3. deliveries.html: the form, stopped before it is sent

const deliveryForm = document.querySelector('#delivery-form');
const formMessage = document.querySelector('#form-message');

function recordDelivery(event) {
  event.preventDefault();
  checkMember();
  checkLitres();

  if (member.classList.contains('invalid')) {
    member.focus();
  } else if (litres.classList.contains('invalid')) {
    litres.focus();
  } else {
    formMessage.textContent = 'Checked: ' + member.value + ', ' + litres.value + ' litres. Nothing is sent yet: ' + 'that needs a server.';
  }
}

if (deliveryForm) {
  deliveryForm.addEventListener('submit', recordDelivery);
}

// ---- 4. routes.html: the routes, filtered as you type

const search = document.querySelector('#route-search');
const routeCount = document.querySelector('#route-count');
const routeSections = document.querySelectorAll('main section');

function filterRoutes() {
  const wanted = search.value.trim().toLowerCase();
  let shown = 0;

  for (const section of routeSections) {
    const words = section.textContent.toLowerCase();
    if (words.includes(wanted)) {
      section.hidden = false;
      shown = shown + 1;
    } else {
      section.hidden = true;
    }
  }

  routeCount.textContent = shown + ' of ' + routeSections.length + ' routes';
}

if (search) {
  search.addEventListener('input', filterRoutes);
}

// ---- 5. deliveries.html: the accepted total

const totalCell = document.querySelector('#accepted-total');

if (totalCell) {
  const rows = document.querySelectorAll('tbody tr');
  let total = 0;

  for (const row of rows) {
    const cells = row.querySelectorAll('td');
    if (cells[4].textContent === 'Yes') {
      total = total + Number(cells[3].textContent);
    }
  }

  totalCell.textContent = total.toFixed(2);
}
