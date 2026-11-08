# Run with /opt/headroom/bin/python inside the named test container.
import time
import urllib.error
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        return None


opener = urllib.request.build_opener(NoRedirect)


def wait_for_health(url, timeout=90):
    deadline = time.monotonic() + timeout
    last_error = 'not checked'
    while time.monotonic() < deadline:
        try:
            with opener.open(url, timeout=2) as response:
                if response.status == 200:
                    print(f'{url}: HTTP 200', flush=True)
                    return
                last_error = f'HTTP {response.status}'
        except (urllib.error.URLError, TimeoutError) as error:
            last_error = str(error)
        time.sleep(1)
    raise RuntimeError(f'{url} not healthy within {timeout}s: {last_error}')


if __name__ == '__main__':
    wait_for_health('http://127.0.0.1:20128/api/health')
    wait_for_health('http://127.0.0.1:8787/health')
