// Where this phone page finds the relay.
// Leave it empty when the page is served by run_local.py or by the relay's own web server (relay/Caddyfile): the page then
// uses its own host (ws://<host>:8080 over http, wss://<host>/ws over https).
// Set it when the page is hosted somewhere else, e.g. on GoDaddy static hosting while the relay runs on a server:
//   window.RELAY_URL = "wss://relay.example.club/ws";
window.RELAY_URL = "";
