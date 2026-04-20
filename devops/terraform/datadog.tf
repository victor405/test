resource "datadog_synthetics_test" "cloudfront_uptime" {
  name    = "cloudfront uptime"
  type    = "api"
  subtype = "http"
  status  = "live"

  request_definition {
    method = "GET"
    url    = "https://d2dk4o2rttwzws.cloudfront.net"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = 200
  }

  locations = ["aws:us-east-1"]

  options_list {
    tick_every = 60

    retry {
      count    = 2
      interval = 3000
    }
  }

  message = "CloudFront DOWN"
  tags    = ["env:dev", "service:frontend"]
}

resource "datadog_synthetics_test" "github_pages_uptime" {
  name    = "github-pages uptime"
  type    = "api"
  subtype = "http"
  status  = "live"

  request_definition {
    method = "GET"
    url    = "https://victor405.github.io/test"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = 200
  }

  locations = ["aws:us-east-1"]

  options_list {
    tick_every = 60

    retry {
      count    = 2
      interval = 3000
    }
  }

  message = "GitHub Pages DOWN"
  tags    = ["env:dev", "service:frontend"]
}