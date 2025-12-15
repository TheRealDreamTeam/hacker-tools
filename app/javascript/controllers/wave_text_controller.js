import { Controller } from "@hotwired/stimulus"

// Wave text animation controller
// Creates a periodic wave pulse that sweeps through the text every minute
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 60000 }, // 60 seconds (1 minute)
    waveSpeed: { type: Number, default: 0.8 }, // Speed of wave sweep (higher = faster)
    amplitude: { type: Number, default: 15 }, // Height of wave
    waveDuration: { type: Number, default: 2000 } // Duration of wave in milliseconds
  }

  connect() {
    this.originalText = this.element.textContent.trim()
    this.splitText()
    this.isAnimating = false
    this.startPeriodicWave()
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
    }
  }

  // Split text into individual characters wrapped in spans
  splitText() {
    const text = this.originalText
    const chars = text.split("")
    
    this.element.innerHTML = chars.map((char, index) => {
      if (char === " ") {
        return `<span class="wave-char" style="display: inline-block; min-width: 0.25em;">&nbsp;</span>`
      }
      return `<span class="wave-char" style="display: inline-block; transition: transform 0.1s ease-out;" data-index="${index}">${char}</span>`
    }).join("")
    
    this.chars = Array.from(this.element.querySelectorAll(".wave-char"))
  }

  // Start periodic wave animation
  startPeriodicWave() {
    // Trigger first wave immediately, then every interval
    this.triggerWave()
    this.timeoutId = setInterval(() => {
      this.triggerWave()
    }, this.intervalValue)
  }

  // Trigger a single wave animation
  triggerWave() {
    if (this.isAnimating) return
    
    this.isAnimating = true
    const startTime = Date.now()
    const duration = this.waveDurationValue
    
    const animate = () => {
      const elapsed = Date.now() - startTime
      const progress = Math.min(elapsed / duration, 1)
      
      // Calculate wave position (0 to 1+ across the text, allowing wave to fully pass through)
      // Add extra range so wave completes fully through the end
      const waveRange = 1 + (0.3 / this.waveSpeedValue) // Extend beyond end to complete wave
      const wavePosition = progress * waveRange
      
      this.chars.forEach((char, index) => {
        // Skip spaces
        if (char.textContent === "\u00A0" || char.textContent === " ") {
          return
        }
        
        // Calculate character position (0 to 1)
        const charPosition = index / this.chars.length
        
        // Calculate distance from wave front
        const distance = Math.abs(charPosition - wavePosition)
        
        // Create wave effect: characters near wave front move up
        let offset = 0
        if (distance < 0.3) {
          // Use sine wave for smooth effect
          const wavePhase = (charPosition - wavePosition) * Math.PI * 2
          const fadeOut = Math.max(0, 1 - distance / 0.3)
          offset = Math.sin(wavePhase) * this.amplitudeValue * fadeOut
        }
        
        char.style.transform = `translateY(${offset}px)`
      })
      
      if (progress < 1) {
        this.animationFrame = requestAnimationFrame(animate)
      } else {
        // Wait a bit longer before resetting to ensure wave fully passes
        setTimeout(() => {
          // Reset all characters to original position smoothly
          this.chars.forEach((char) => {
            char.style.transition = "transform 0.3s ease-out"
            char.style.transform = "translateY(0px)"
          })
          // Reset transition after animation completes
          setTimeout(() => {
            this.chars.forEach((char) => {
              char.style.transition = "transform 0.1s ease-out"
            })
            this.isAnimating = false
          }, 300)
        }, 100)
      }
    }
    
    animate()
  }
}
