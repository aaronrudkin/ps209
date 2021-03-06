#' Make pretty printout of piped code block string.
#'
#' @param ptext string of pipe-separated commands.
#'
#' @return pretty version of code string.
#'
#' @importFrom magrittr %>%
#' @importFrom stringr str_replace str_replace_all
#'
pprintp <- function(ptext) {
   ptext %>%
     stringr::str_replace_all("%>%", "%>%\n  ") %>%
     stringr::str_replace("%>%\n  ", "%>%")
}

#' Make a string of separator characters to use in print outs.
#'
#' @param char Character to use.
#' @param line_length Number of characters in the string.
#'
#' @return Separator string.
#'
#'
#' @import stringr
#' @import magrittr
#'
sepline <- function(char="-", line_length=60) {
  paste0(paste0(rep(char,line_length), collapse=""),"\n")
}

#' Display intermediate results of blocks of piped expressions.
#'
#' @param call_expression Block of dplyr or other piped commands.
#'
#' @return Result of evaluating \code{expr}.
#'
#' @importFrom rlang enexpr expr_text env
#' @importFrom magrittr %>%
#' @importFrom stringr str_split str_replace_all
#' @importFrom utils head
#'
#' @export
#'
#' @examples
#' library(tidyverse)
#' step_through_pipes({
#'    starwars %>%
#'       mutate(bmi=mass/((height/100)^2)) %>%
#'       select(name:mass, bmi) %>%
#'       filter(bmi<22) %>%
#'       gather(feature, value, -name) %>%
#'       arrange(name, feature)
#' })
#'
#'
step_through_pipes <- function(call_expression) {
  # How long should pipe chunks be padded to?
  max_chunk_length =
    expr_text(enexpr(call_expression)) %>%
    str_split("%>%") %>%
    sapply(nchar) %>%
    max() + 6

  cat("\nStepping through pipes:\n")
  le <- env(`%>%` = function(lhs, rhs) {
    # Get desired string padding length
    ref_env = parent.frame()
    string_length = get("string_length", envir = ref_env)

    # Produce header
    current_call <- paste0("lhs %>% ", deparse(substitute(rhs)), "\n")
    pretty_pcall <- pprintp(current_call %>% str_replace_all("lhs","."))

    # Produce temp result
    result <- tryCatch(
      { eval(parse(text=current_call)) },
      error = function(e) {
        past_error = get("past_error", envir = ref_env)
        if(past_error > 0)
        {
          return(NULL)
        }

        print_header(pretty_pcall, string_length)
        print("Error in this step of the pipe chain. Error details:")
        print(e)
        assign("past_error", 1, envir = ref_env)
        return(NULL)
      })

    if(is.null(result)) {
      stop("Cannot complete pipe chain because of error.", call. = FALSE)
    }

    print_header(pretty_pcall, string_length)
    print(head(result))
    # Return result
    cat("\n")
    result
  },
  `string_length` = max_chunk_length,
  `past_error` = 0
  )
  total_result <- eval(expr = enexpr(call_expression), envir = le)
  cat("Pipes completed!\n\n")
  invisible(total_result)
}

#' Stub function which pretty-prints a call header
#'
#' @param call A character string representing a pipe call
#' @param length A number indicating how long to pad the header to
print_header <- function(call, length) {
  cat(sepline("=", length))
  cat(call)
  cat(sepline("=", length))
}
