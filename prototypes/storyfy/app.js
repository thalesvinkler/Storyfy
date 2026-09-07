const app = document.querySelector("#app");
const journey = document.querySelector("#journey");
const screens = ["Escolher periodo", "Curadoria", "Revisao", "Legenda", "Aprovacao"];

const monthNames = ["janeiro", "fevereiro", "marco", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
const monthShortNames = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
const state = {
  screen: 0,
  progress: 0,
  month: 5,
  year: 2026,
  selected: Array.from({ length: 12 }, (_, index) => index < 10),
  cover: 1,
  profile: "",
  profileConnected: false,
  caption: "Junho foi feito de movimento, encontros e momentos que mereciam ficar. Entre novos caminhos, dias de trabalho, treinos e tempo com quem importa, escolhi estas lembrancas para contar um pouco da historia.\n\nSeguimos construindo."
};

const photos = [
  ["Viagem", 96], ["Nos dois", 98], ["Familia", 94], ["Amigos", 93],
  ["Treinos", 91], ["Trabalho", 88], ["Rancho", 95], ["Cidade", 86],
  ["Detalhes", 84], ["Viagem", 92], ["Casa", 87], ["Paisagem", 90]
];

const events = [
  ["✈️", "Viagem", "3 de 164"],
  ["👨‍👩‍👧", "Familia", "2 de 87"],
  ["🥂", "Amigos", "2 de 64"],
  ["🏃", "Rotina", "3 de 171"]
];

function pos(index) { return `${(index % 4) * 33.333}% ${Math.floor(index / 4) * 50}%`; }
function brand() { return '<div class="brand"><span class="brand-mark">▣</span> STORYFY</div>'; }
function periodTitle() { return `${monthNames[state.month][0].toUpperCase()}${monthNames[state.month].slice(1)} de ${state.year}`; }
function go(screen) { state.screen = screen; render(); }
function button(label, screen, className = "primary") { return `<button class="${className}" onclick="go(${screen})">${label}</button>`; }

function photo(index, interactive = false) {
  const selected = state.selected[index];
  const classes = `photo ${selected ? "selected" : ""} ${state.cover === index ? "cover" : ""}`;
  const click = interactive ? `onclick="togglePhoto(${index})"` : "";
  return `<button class="${classes}" style="background-position:${pos(index)}" ${click} aria-label="${photos[index][0]}"><span class="score">${photos[index][1]}</span></button>`;
}

function updatePeriod(field, value) {
  state[field] = Number(value);
  render();
}

function shiftYear(delta) {
  state.year += delta;
  render();
}

function togglePhoto(index) {
  state.selected[index] = !state.selected[index];
  if (!state.selected[state.cover]) state.cover = state.selected.findIndex(Boolean);
  render();
}

function setCover() {
  const chosen = state.selected.map((value, index) => value ? index : -1).filter(index => index >= 0);
  const current = chosen.indexOf(state.cover);
  state.cover = chosen[(current + 1) % chosen.length];
  render();
}

function processStory() {
  go(1);
  state.progress = 18;
  const timer = setInterval(() => {
    state.progress = Math.min(100, state.progress + 14);
    render();
    if (state.progress >= 100) {
      clearInterval(timer);
      setTimeout(() => go(2), 350);
    }
  }, 250);
}

function connectProfile() {
  const input = document.querySelector("#profile-input");
  state.profile = input.value.trim();
  if (!state.profile) return;
  state.profileConnected = true;
  render();
}

function disconnectProfile() {
  state.profileConnected = false;
  state.profile = "";
  render();
}

function regenerate() {
  state.caption = state.profileConnected
    ? "Um mes de caminhos novos, gente querida e dias que passaram depressa. Junho teve trabalho, movimento e aquelas pausas que colocam tudo no lugar. ✨\n\nUm pouco do que quero guardar por aqui."
    : "Junho em alguns retratos: novos caminhos, boas conversas, rotina e pausas que fizeram o mes valer a pena. Do jeito que eu quero lembrar.";
  render();
}

function updateCaption(value) { state.caption = value; }

function renderJourney() {
  journey.innerHTML = screens.map((name, index) => `<li class="${index === state.screen ? "active" : ""}">${String(index + 1).padStart(2, "0")} &nbsp; ${name}</li>`).join("");
}

function render() {
  renderJourney();
  const views = [month, processing, review, caption, approval, settings];
  app.innerHTML = views[state.screen]();
}

function month() {
  const months = monthShortNames.map((name, index) => `<button class="${index === state.month ? "active" : ""}" onclick="updatePeriod('month', ${index})">${name}</button>`).join("");
  return `<div class="view home-view"><div class="top-row">${brand()}<button class="icon-button plain" onclick="go(5)" title="Configurar estilo de legenda" aria-label="Configuracoes">⚙︎</button></div><div class="home-heading"><span class="eyebrow">NOVA HISTORIA</span><h2>Qual mes voce quer reviver?</h2><p class="muted">Escolha o periodo. O restante fica por conta do Storyfy.</p></div><div class="period-calendar" aria-label="Selecionar mes e ano"><div class="calendar-year"><button onclick="shiftYear(-1)" aria-label="Ano anterior">‹</button><strong>${state.year}</strong><button onclick="shiftYear(1)" aria-label="Proximo ano">›</button></div><div class="month-grid">${months}</div></div><div class="spacer"></div><div class="profile-hint ${state.profileConnected ? "connected" : ""}"><span>${state.profileConnected ? "✓" : "✦"}</span><div><strong>${state.profileConnected ? "Seu estilo esta conectado" : "Legenda com a sua voz"}</strong><small>${state.profileConnected ? `Baseada em ${state.profile}` : "Conecte seu perfil para o Storyfy aprender como voce escreve."}</small></div><button onclick="go(5)">${state.profileConnected ? "Editar" : "Configurar"}</button></div><button class="primary" onclick="processStory()">Montar historia de ${monthNames[state.month]}</button></div>`;
}

function processing() {
  const done1 = state.progress > 32, done2 = state.progress > 60, done3 = state.progress > 85;
  return `<div class="view">${brand()}<div class="progress-ring" style="--progress:${state.progress}%"><strong>${state.progress}%</strong></div><h2 class="center">Montando sua historia</h2><p class="muted center">${state.progress < 40 ? "Removendo repetidas e screenshots" : state.progress < 75 ? "Agrupando viagens, encontros e rotina" : "Criando uma sequencia com ritmo"}</p><div class="steps"><div class="${done1 ? "done" : ""}">${done1 ? "✓" : "○"} Filtrar imagens</div><div class="${done2 ? "done" : ""}">${done2 ? "✓" : "○"} Agrupar eventos</div><div class="${done3 ? "done" : ""}">${done3 ? "✓" : "○"} Criar narrativa</div></div></div>`;
}

function review() {
  const count = state.selected.filter(Boolean).length;
  const eventCards = events.map(event => `<div class="event"><b>${event[0]}</b><div>${event[1]}<span>${event[2]}</span></div></div>`).join("");
  return `<div class="view"><div class="header-row"><div><span class="eyebrow">MOMENTOS ENCONTRADOS</span><h2>Sua narrativa</h2><p class="muted">${count} fotos escolhidas</p></div><button class="icon-button" onclick="setCover()" title="Trocar capa">★</button></div><div class="event-strip">${eventCards}</div><div class="photo-grid">${photos.map((_, index) => photo(index, true)).join("")}</div><p class="selection-help">Toque para remover ou adicionar. Use ★ para trocar a capa.</p><div class="spacer"></div>${button("Criar legenda", 3)}${button("Voltar", 0, "secondary")}</div>`;
}

function caption() {
  return `<div class="view"><button class="back" onclick="go(2)" aria-label="Voltar">‹</button><span class="eyebrow">LEGENDA</span><h2>A voz do seu mes</h2><p class="muted">${state.profileConnected ? `Inspirada no jeito que voce escreve em ${state.profile}.` : "Edite livremente ou conecte seu perfil para personalizar o estilo."}</p><div class="chips">${events.map(event => `<span class="chip">${event[0]} ${event[1]}</span>`).join("")}</div><textarea oninput="updateCaption(this.value)">${state.caption}</textarea><button class="secondary outlined" onclick="regenerate()">✦ Tentar outra legenda</button>${button("Ver preview do carrossel", 4)}</div>`;
}

function approval() {
  const selected = state.selected.map((value, index) => value ? index : -1).filter(index => index >= 0);
  const slides = selected.slice(0, 5).map((index, slideIndex) => `<div class="carousel-slide photo" style="background-position:${pos(index)}"><span>${slideIndex + 1}/${selected.length}</span></div>`).join("");
  return `<div class="view approval-view"><button class="back" onclick="go(3)" aria-label="Voltar">‹</button><span class="eyebrow">PREVIEW DO CARROSSEL</span><div class="carousel-preview">${slides}</div><div class="carousel-dots">${selected.slice(0, 5).map((_, index) => `<i class="${index === 0 ? "active" : ""}"></i>`).join("")}</div><div class="post-preview"><div class="post-profile"><span>S</span><strong>seu_perfil</strong><small>•••</small></div><p>${state.caption.replace(/\n/g, "<br>")}</p></div><div class="spacer"></div><button class="primary" onclick="this.closest('.view').innerHTML = success()">Aprovar historia</button>${button("Voltar para editar", 2, "secondary")}</div>`;
}

function settings() {
  if (state.profileConnected) {
    return `<div class="view"><button class="back" onclick="go(0)" aria-label="Voltar">‹</button><span class="eyebrow">SEU ESTILO</span><h2>Legenda com a sua voz</h2><div class="profile-connected"><div class="avatar">@</div><div><strong>${state.profile}</strong><span>Perfil analisado</span></div><b>✓</b></div><p class="muted">O Storyfy identificou padroes nas suas legendas publicas anteriores.</p><div class="style-grid"><div><span>Tom</span><strong>Pessoal e direto</strong></div><div><span>Tamanho</span><strong>Curto a medio</strong></div><div><span>Emojis</span><strong>Poucos, no final</strong></div><div><span>Hashtags</span><strong>Raramente</strong></div></div><div class="privacy-note">A analise serve apenas para sugerir textos. Nada e publicado sem sua aprovacao.</div><div class="spacer"></div><button class="secondary danger" onclick="disconnectProfile()">Desconectar perfil</button><button class="primary" onclick="go(0)">Concluir</button></div>`;
  }
  return `<div class="view"><button class="back" onclick="go(0)" aria-label="Voltar">‹</button><span class="eyebrow">PERSONALIZAR LEGENDA</span><h2>Escreva como voce</h2><p class="muted">Informe seu perfil publico. O Storyfy usa suas postagens anteriores para reconhecer tom, tamanho, emojis e hashtags.</p><label class="profile-field">Link ou @ do perfil<input id="profile-input" type="text" placeholder="@seu_perfil" value="${state.profile}"></label><div class="analysis-example"><span>O que sera analisado</span><div>“Um fim de semana para guardar...”</div><div>“Novos caminhos, mesma companhia ✨”</div><div>“Dias bons por aqui.”</div></div><div class="privacy-note">No app real, essa conexao dependera da permissao da plataforma. Voce tambem podera colar exemplos manualmente.</div><div class="spacer"></div><button class="primary" onclick="connectProfile()">Analisar meu estilo</button><button class="secondary" onclick="go(0)">Agora nao</button></div>`;
}

function success() {
  return `<div class="success"><div class="seal">✓</div><h2>Historia aprovada</h2><p class="muted">O carrossel esta pronto para salvar no Fotos ou compartilhar.</p><br><button class="primary" onclick="go(0)">Criar nova historia</button></div>`;
}

render();
