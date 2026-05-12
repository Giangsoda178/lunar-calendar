const networkState = $state({
  isOnline: typeof navigator === "undefined" ? true : navigator.onLine,
})

let listenersBound = false

function updateNetworkState() {
  networkState.isOnline = navigator.onLine
}

function bindListeners() {
  if (listenersBound || typeof window === "undefined") return
  window.addEventListener("online", updateNetworkState)
  window.addEventListener("offline", updateNetworkState)
  listenersBound = true
}

export function useNetworkStatus() {
  bindListeners()

  return {
    get isOnline() {
      return networkState.isOnline
    },
  }
}
