test_performance <- function(n, repetitions = 3) {
  times <- numeric(repetitions)
  
  prime_factors <- function(num) {
    factors <- c()
    d <- 2
    while (num > 1) {
      while (num %% d == 0) {
        factors <- c(factors, d)
        num <- num / d
      }
      d <- d + 1
      if (d * d > num && num > 1) {
        factors <- c(factors, num)
        break
      }
    }
    return(factors)
  }
  
  for (i in 1:repetitions) {
    start_time <- Sys.time()
    result <- prime_factors(n)
    end_time <- Sys.time()
    times[i] <- as.numeric(difftime(end_time, start_time, units = "secs"))
  }
  
  avg_time <- mean(times)
  
  list(factors = result, avg_time_taken = avg_time)
}

# Example usage:
n <- 6352349375656789
performance <- test_performance(n)
print(performance)