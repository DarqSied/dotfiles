const NAME = "DarqSied";

const CARDS = [
  {
    name: "Adda",
    icon: "ri-book-open-line",
    link: "https://adda247.com/",
  },
  {
    name: "YouTube",
    icon: "ri-youtube-line",
    link: "http://piped.kavin.rocks/feed/",
  },
  {
    name: "Anime",
    icon: "ri-tv-line",
    link: "https://gogoanime.gg/",
  },
  {
    name: "MyAnimeList",
    icon: "ri-eye-line",
    link: "https://myanimelist.net/",
  },
  {
    name: "Gmail",
    icon: "ri-mail-unread-line",
    link: "https://mail.google.com/mail/",
  },
  {
    name: "Outlook",
    icon: "ri-mail-line",
    link: "https://outlook.com/",
  },
  {
    name: "Protonmail",
    icon: "ri-mail-lock-line",
    link: "https://protonmail.com/",
  },
  {
    name: "Netbanking",
    icon: "ri-bank-line",
    link: "https://netbanking.hdfc.com/netbanking/",
  },
];

/* -------------------------------------------------------- */

/******************/
/* CLOCK FUNCTION */
/******************/

const DAYS = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
];

const MONTHS = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
];

const updateDate = () => {
    // Create a new Date object and get the complete Date/Time information
    const completeDate = new Date();

    // Time Variables
    let currentHour = formatDigit(completeDate.getHours());
    let currentMinute = formatDigit(completeDate.getMinutes());

    // Date Variables
    let currentDay = completeDate.getDay();
    let currentNumber = completeDate.getDate();
    let currentMonth = completeDate.getMonth();
    let currentYear = completeDate.getFullYear();

    // Update the Time
    currentTime.innerHTML = `${currentHour}:${currentMinute}`;

    // Update the Date
    currentDate.innerHTML = `${DAYS[currentDay]} ${currentNumber}, ${MONTHS[currentMonth]} ${currentYear}`;

    // Create a Loop
    setTimeout(() => {
        updateDate();
    }, 1000);
};

const formatDigit = (digit) => {
    return digit > 9 ? `${digit}` : `0${digit}`;
};

/******************/
/* CARDS FUNCTION */
/******************/

const printCards = () => {
    for (const card of CARDS) {
        let currentCard = document.createElement("a");
        currentCard.setAttribute("target","_blank")
        let currentCardText = document.createElement("p");
        currentCardText.appendChild(document.createTextNode(card.name));
        let currentCardIcon = document.createElement("i");
        currentCardIcon.classList.add(card.icon);

        // Style the Card Element
        currentCard.classList.add("card");
        currentCard.href = card.link;

        // Style the Icon
        currentCardIcon.classList.add("card__icon");

        // Style the Text
        currentCardText.classList.add("card__name");

        currentCard.append(currentCardIcon);
        currentCard.append(currentCardText);
        cardContainer.appendChild(currentCard);
    }
};

/****************/
/* STARTER CODE */
/****************/

userName.innerHTML = NAME;
printCards();
updateDate();
