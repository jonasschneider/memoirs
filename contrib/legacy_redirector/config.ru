run proc { |env|
  loc = "https://memoirs.jonasschneider.com"+env["PATH_INFO"]
  [302, { "Location" => loc }, []]
}
