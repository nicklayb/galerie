# Mailer

Nectarine has to send emails here and there and uses [Swoosh](https://hexdocs.pm/swoosh/Swoosh.Adapters.SMTP.html) to do so. The application is already configured to support the following adapters (defined using `MAILER_ADAPTER`.

- `"local"`: Uses a faker email sender that sends to a local view where you can inspect them.
- `"smtp"`: Uses a SMTP server to send a email. You need a few more env variables in order for this to work. See [SMTP](#smtp) section.

## Local

During development, we use the `Swoosh.Adapters.Local`. This sends the email in memory only and can be browsed through the `http://localhost:4000/mailbox` path.

## SMTP

To use SMTP, make sure your environment defines the following variables:

**Mendatory**

- `MAILER_ADAPTER=smtp`: to enable SMTP
- `MAILER_SMTP_RELAY`: The server to use
- `MAILER_SMTP_USERNAME`: The server's username. Depending on the server, this can be the email sender email address.
- `MAILER_SMTP_PASSWORD`: The server's account password.

**Optional**

Depending on the server, you might need to update change the following variables

- `MAILER_SMTP_SSL`: Enables SSL (defaults to `true`)
- ̀`MAILER_SMTP_TLS`: Needs to be one of `always`, `never` or `if_available` to configure TLS (defaults to `always`)
- ̀`MAILER_SMTP_AUTH`: Needs to be one of `always`, `never` or `if_available` to enable Auth (defaults to `always`)
