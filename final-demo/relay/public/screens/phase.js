// Story phases from the game server ({"t": "phase"}, sent to every phone): while a comic or a question is on the main
// screen the controls step aside; only the Royal Seer can answer a question, after the council talks it over.

export const STORY_SCREENS = new Set(["lobby", "comic", "question", "end"]);

export function showsStoryScreen(phase) {
  return STORY_SCREENS.has(phase?.phase);
}

// A key for the screen as drawn: the app redraws only when it changes, so a tap is never lost to a 10 Hz refresh.
export function storyKey(phase, role, selected, sent) {
  return ["story", phase?.phase, phase?.scene, phase?.question?.id || "", role, selected || "", sent || ""].join(":");
}

export function renderStory(phase, role, selected = "", sent = "") {
  const mode = phase?.phase;
  if (mode === "question" && phase.question) return question(phase.question, role, selected, sent);
  const cards = {
    lobby: ["The Royal Ball", "You're in!", "The court begins when the host starts the story. Keep this page open."],
    comic: ["Story time", "Watch the main screen", "The controls come back when Prince Hamlet flies again."],
    end: ["The End", "Thank you for playing", "Look at the main screen for the Royal Decree."],
  };
  const [eyebrow, title, copy] = cards[mode] || cards.comic;
  return `
    <section class="screen story-screen" aria-labelledby="story-title">
      <p class="eyebrow">${eyebrow}</p>
      <h1 id="story-title">${title}</h1>
      <p class="lede">${copy}</p>
    </section>`;
}

function question(q, role, selected, sent) {
  const text = escape(q.text);
  if (role !== "seer") {
    return `
      <section class="screen story-screen" aria-labelledby="story-title">
        <p class="eyebrow">A question for the council</p>
        <h1 id="story-title">Discuss with your council</h1>
        <p class="lede">${text}</p>
        <p class="story-options"><b>A</b> ${escape(q.a)}<br><b>B</b> ${escape(q.b)}</p>
        <p class="microcopy">The Royal Seer answers for everyone.</p>
      </section>`;
  }
  if (sent) {
    return `
      <section class="screen story-screen" aria-labelledby="story-title">
        <p class="eyebrow">Answer sent</p>
        <h1 id="story-title">${escape(sent)}: ${escape(sent === "A" ? q.a : q.b)}</h1>
        <p class="lede">Look at the main screen.</p>
      </section>`;
  }
  const option = (key, label) =>
    `<button class="answer-button${selected === key ? " is-active" : ""}" data-answer="${key}"><b>${key}</b><span>${escape(label)}</span></button>`;
  return `
    <section class="screen story-screen" aria-labelledby="story-title">
      <p class="eyebrow">Royal Seer: you answer</p>
      <h1 id="story-title">${text}</h1>
      <p class="microcopy">Talk it over with your council, then choose and confirm.</p>
      <div class="answer-grid">${option("A", q.a)}${option("B", q.b)}</div>
      <button class="primary" id="confirm-answer"${selected ? "" : " disabled"}>${selected ? `Confirm ${selected}` : "Choose A or B"}</button>
    </section>`;
}

export function answerMessage(choice) {
  if (choice !== "A" && choice !== "B") throw new Error("An answer is A or B");
  return { t: "answer", role: "seer", choice };
}

function escape(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}
