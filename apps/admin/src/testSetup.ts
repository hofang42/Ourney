import '@testing-library/jest-dom'
import { beforeEach } from 'vitest'

beforeEach(() => {
  try {
    window.localStorage.clear()
  } catch {
    // Ignore
  }
})
