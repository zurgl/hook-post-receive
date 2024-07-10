import argv
import envoy
import gleam/int
import gleam/order
import gleam/result.{unwrap}
import gleam/string.{append, compare}
import gleamyshell.{Abort, Failure}
import simplifile

// envoy.set("WORK_TREE", "/home/nginx/wtree")
pub fn env() -> Nil {
  envoy.set("GIT_DIR", "/home/nginx/momo.git")
  envoy.set("BRANCH", "master")
  envoy.set("LOG", "/home/nginx/log")
}

pub fn logger(info: String, is_err: Bool) -> Nil {
  let logfile = "/home/nginx/logfile"
  case is_err {
    True -> {
      append("Error: ", string.trim(info))
      |> simplifile.append(to: logfile)
      |> result.unwrap(Nil)
    }
    False -> {
      append("Info: ", string.trim(info))
      |> simplifile.append(to: logfile)
      |> result.unwrap(Nil)
    }
  }
}

pub fn main() {
  env()
  case argv.load().arguments {
    [_, _, ref] ->
      case dispatch(ref) {
        Ok(_) -> checkout()
        Error(_) -> logger("dispatch", True)
      }
    _ -> logger("Usage: post-receive <oldrev> <newrev> <ref>", True)
  }
}

pub fn get_branch() -> String {
  envoy.get("BRANCH") |> unwrap("master")
}

pub fn get_head() -> String {
  append(to: "refs/heads/", suffix: get_branch())
}

pub fn dispatch(ref: String) -> Result(Nil, Nil) {
  case compare(ref, get_head()) {
    order.Eq -> Ok(Nil)
    order.Lt -> Error(Nil)
    order.Gt -> Error(Nil)
  }
}

pub fn checkout() -> Nil {
  case
    gleamyshell.execute("git", in: "/home/nginx/wtree/front", args: [
      "checkout",
      "-f",
      get_branch(),
    ])
  {
    Ok(info) -> logger(info, False)
    Error(Failure(output, exit_code)) -> {
      let info =
        "Whoops!\nError ("
        <> int.to_string(exit_code)
        <> "): "
        <> string.trim(output)
      logger(info, True)
    }
    Error(Abort(_)) -> logger("Abort checkout", True)
  }
}
