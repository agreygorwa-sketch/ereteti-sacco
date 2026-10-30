// Week 8: delivery-form validation for the deliveries page.
// Static site: nothing is saved anywhere; this only checks the form
// before it is submitted and reports back in the message slots.
document.addEventListener('DOMContentLoaded', function () {
    var form = document.getElementById('delivery-form');
    if (!form) return;

    var member = document.getElementById('member');
    var litres = document.getElementById('litres');
    var memberMessage = document.getElementById('member-message');
    var litresMessage = document.getElementById('litres-message');
    var formMessage = document.getElementById('form-message');

    function checkMember() {
        var ok = /^ER-[0-9]{4}$/.test(member.value.trim());
        memberMessage.textContent = ok ? '' : 'Member number looks like ER-0000.';
        return ok;
    }

    function checkLitres() {
        var value = parseFloat(litres.value);
        var ok = !isNaN(value) && value > 0;
        litresMessage.textContent = ok ? '' : 'Enter litres above zero.';
        return ok;
    }

    member.addEventListener('input', checkMember);
    litres.addEventListener('input', checkLitres);

    form.addEventListener('submit', function (event) {
        event.preventDefault();
        var ok = checkMember() && checkLitres();
        if (!ok) {
            formMessage.textContent = 'Fix the fields above first.';
            return;
        }
        formMessage.textContent = 'Delivery recorded (demo: nothing is saved).';
    });
});
