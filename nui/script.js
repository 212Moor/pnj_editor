let allPeds = [];

// ✅ Reçoit le peds.json depuis client.lua
window.addEventListener("message", e => {
  const d = e.data;
  if (d.action === "open") document.body.style.display = "flex";
  if (d.action === "close") document.body.style.display = "none";
  if (d.action === "minimize") document.getElementById("menu").classList.add("minimized");
  if (d.action === "restore") document.getElementById("menu").classList.remove("minimized");

  // Ajout progressif des peds
  if (d.action === "addPeds" && d.peds) {
    const sel = document.getElementById("pedSelect");
    d.peds.forEach(name => {
      const opt = document.createElement("option");
      opt.value = name;
      opt.textContent = name;
      sel.appendChild(opt);
    });
  }
});


function populatePedList(list) {
  const sel = document.getElementById("pedSelect");
  sel.innerHTML = "";
  list.forEach(name => {
    const opt = document.createElement("option");
    opt.value = name;
    opt.textContent = name;
    sel.appendChild(opt);
  });
}

document.getElementById("search").addEventListener("input", e => {
  const f = e.target.value.toLowerCase();
  const filtered = allPeds.filter(p => p.toLowerCase().includes(f));
  populatePedList(filtered);
});

// ✅ Animations
const animCategories = {
  social: [
    "amb@world_human_smoking@male@male_b@idle_a|idle_c",
    "cellphone@|cellphone_call_listen_base",
    "amb@world_human_cheering@male_a|base"
  ],
  travail: [
    "amb@prop_human_parking_meter@male@idle_a|idle_a",
    "amb@world_human_gardener_plant@male@idle_a|idle_a"
  ],
  fun: [
    "mini@strip_club@private_dance@part1|priv_dance_p1",
    "anim@mp_player_intcelebrationfemale@slow_clap|slow_clap"
  ],
  combat: [
    "melee@unarmed@streamed_core_fps|ground_attack_on_spot",
    "rcmextreme3|idle"
  ]
};

const animCat = document.getElementById("animCategory");
const animSelect = document.getElementById("animSelect");

function updateAnimList() {
  animSelect.innerHTML = "";
  animCategories[animCat.value].forEach(a => {
    const opt = document.createElement("option");
    opt.value = a;
    opt.textContent = a.split("|")[1];
    animSelect.appendChild(opt);
  });
}
animCat.onchange = updateAnimList;
updateAnimList();

// ✅ Boutons
document.getElementById("spawn").onclick = () => {
  const model = document.getElementById("pedSelect").value;
  if (!model) return;
  fetch(`https://${GetParentResourceName()}/spawnPed`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model })
  });
};

document.getElementById("apply").onclick = () => {
  const selected = animSelect.value;
  if (!selected) return;
  const [dict, anim] = selected.split("|");
  fetch(`https://${GetParentResourceName()}/applyAnim`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ dict, anim })
  });
};

document.getElementById("save").onclick = () => fetch(`https://${GetParentResourceName()}/saveScene`, { method: "POST" });
document.getElementById("place").onclick = () => fetch(`https://${GetParentResourceName()}/togglePlacement`, { method: "POST" });
document.getElementById("close").onclick = () => fetch(`https://${GetParentResourceName()}/close`, { method: "POST" });
