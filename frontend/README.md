# Authentication with Ember Simple Auth

At Echobind, we get our client apps up and running quickly. One of the
best tools we use in our toolkit is [ember-simple-auth][1] developed by
simplabs. It helps you implement authentication in your Ember application
that is lightweight and easy to integrate. I’m going to show you how to
get started quickly. So let’s get started.

**Installing ember-simple-auth**

To get started, let’s create a new ember app:

```bash
mkdir ember-simple-auth
cd ember-simple-auth
ember new frontend
```
When you run this, you should see something like this:

```bash
installing app
  create .editorconfig
  create .ember-cli
  create .eslintrc.js
  create .travis.yml
  create .watchmanconfig
  create README.md
...
```

Yes, I’m using NPM. Don’t judge me — it works!

Ok, so let’s `cd` into our new application: `cd frontend`.

Update packages and edit `.ember-cli`:

```
// .ember-cli
{
  "liveReload": true,
  "watcher": "polling",
  "disableAnalytics": false
}
```

```bash
ncu
ncu -u
npm install
```

We’ll start out by installing ember-simple-auth:

```bash
ember install ember-simple-auth
```

When you run that, you should see:

```bash
NPM: Installing ember-simple-auth ...
Installed addon package.
```

Cool! We’re all set with installation. Let’s now move to configuring our
application.

**Adapter Setup**

First, we’ll start out by creating our application adapter:

```bash
ember g adapter application

installing adapter
  create app/adapters/application.js
installing adapter-test
  create tests/unit/adapters/application-test.js
```

Here, we’re using a generator to create our default application adapter.
This will generate this file:

```javascript
// frontend/app/adapters/application.js
import DS from 'ember-data';

export default DS.JSONAPIAdapter.extend();
```

We’ll need to do a couple things here, but essentially our file will be
transformed to this:

```javascript
// auth-example-frontend/app/adapters/application.js
import JSONAPIAdapter from 'ember-data/adapters/json-api';
import DataAdapterMixin from 'ember-simple-auth/mixins/data-adapter-mixin';
import config from 'frontend/config/environment';

export default JSONAPIAdapter.extend(DataAdapterMixin, {
  host: config.apiUrl,
  namespace: config.apiNamespace,
  authorizer: 'authorizer:application'
});
```

Here’s what’s happening:

1. We’re utilizing `JSONAPIAdapter`
2. `DataAdapterMixin` will be extended into the adapter
3. The environment `config` will be used to determine the `host` and
   `namespace`

Let’s define these values in `config/environment.js`:

```javascript
let ENV = {
  ...

  APP: { },

  apiNamespace: 'api',
  apiUrl: null
};
```

This essentially means the following:

1. We’ll be defining our `apiUrl` via the proxy option in `ember-cli`
   (e.g. `ember s --proxy http://localhost:4000`)
2. The `api` is namespaced to `api` (e.g.
   `http://localhost:4000/api/users`

**Authenticator Setup**

What is an authenticator?

> The authenticator authenticates the session. The actual mechanism used
> to do this might, e.g., post a set of credentials to a server and in
> exchange retrieve an access token, initiating authentication against
> an external provider

The TL;DR is that the authenticator is used to authenticate a session
with the credentials passed in. For the purposes of this article, we’ll
be using [OAuth2PasswordGrantAuthenticator][2] - giving us the ability
to authenticate with an identifier (username, email, etc…) with a
password.

To generate the authenticator we can run:

```bash
ember g authenticator oauth2 --base-class=oauth2
```

This should output the following:

```bash
installing authenticator
  create app/authenticators/oauth2.js
```

And it should create the following:

```javascript
// frontend/app/authenticators/oauth2.js
import OAuth2PasswordGrant from 'ember-simple-auth/authenticators/oauth2-password-grant';

export default OAuth2PasswordGrant.extend();
```

Now, we need to define [serverTokenEndpoint][3]. What does this property
do?

> The endpoint on the server that authentication and token refresh
> requests are sent to.

Let’s define it:

```javascript
// frontend/app/authenticators/oauth2.js
import OAuth2PasswordGrant from 'ember-simple-auth/authenticators/oauth2-password-grant';
import config from 'frontend/config/environment';

const host = config.apiUrl || '';
const namespace = config.apiNamespace;
const serverTokenEndpoint = [ host, namespace, 'token' ];

export default OAuth2PasswordGrant.extend({
  serverTokenEndpoint: serverTokenEndpoint.join('/')
});
```

The code above generates a `serverTokenEndpoint` by joining the `host`,
`namespace` with the string `token`. So if we had the following:

```javascript
host = 'http://localhost:4000'
namespace = 'api'
token = 'token'
```

We would get the following as the value for `serverTokenEndpoint`:

```bash
http://localhost:4000/api/token
```

**Authorizer Setup**

What is an authorizer?

> Authorizers use the session data acquired by an authenticator when
> authenticating the session to construct authorization data that can,
> e.g., be injected into outgoing network requests.

The TL;DR here is that, once authenticated, the authorizer uses the
session data to construct the authorization data for your requests. In
our example, this will generate the following header:

```javascript
Authorization: Bearer s0m3tok3n1
```

Lucky for us, ember-simple-auth makes this easy to setup. We’ll be
utilizing [OAuth2BearerAuthorizer][4], as it gives us the functionality
we need out of the box to generate the header above.

All we need to do is run the following command:

```bash
ember g authorizer application --base-class=oauth2
```

This should output:

```bash
installing authorizer
  create app/authorizers/application.js
```

And it should create the following:

```javascript
// frontend/app/authorizers/application.js
import OAuth2Bearer from 'ember-simple-auth/authorizers/oauth2-bearer';

export default OAuth2Bearer.extend();
```

**Hooking Up Ember Simple Auth**

We need to hook up the plumbing now that we’re done with configuration.

#### Creating An Application Route

```bash
touch app/routes/application.js
```

```javascript
// frontend/routes/application.js
import Route from '@ember/routing/route';
import ApplicationRouteMixin from 'ember-simple-auth/mixins/application-route-mixin';

export default Route.extend(ApplicationRouteMixin, {
  routeAfterAuthentication: 'dashboard'
});
```

```
// app/templates/application.hbs
{{outlet}}
```

#### Creating The Sign Up Route

The first thing we need to do here is create our sign-up route.

```bash
ember g route sign-up
```

You should get this output:

```bash
ember g route sign-up
installing route
  create app/routes/sign-up.js
  create app/templates/sign-up.hbs
updating router
  add route sign-up
installing route-test
  create tests/unit/routes/sign-up-test.js
```

Let’s open up the generated sign-up template and put the following in
there:

```
// app/templates/sign-up.hbs
<form {{action "onSignUp" email password on="submit"}}>
  <div>
    <label>Email</label>
    {{input type="email" value=email}}
  </div>
  <div>
    <label>Password</label>
    {{input type="password" value=password}}
  </div>
  <button type="submit">Sign Up</button>
</form>
```

We’re creating a very simple form with `email` and `password` fields.
When the user clicks "Sign Up" — we’ll call the onSignUp action, passing
it the email and password values. Let’s define that action.

```javascript
// frontend/routes/sign-up.js
import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

const AUTHENTICATOR = 'authenticator:oauth2';

export default Route.extend({
  session: service(),

  actions: {
    async onSignUp(email, password) {
      let attrs = { email, password };
      let user = this.store.createRecord('user', attrs);

      await user.save();

      let session = this.get('session');

      await session.authenticate(AUTHENTICATOR, email, password);
    }
  }
});
```

The above is just adding an `onSignUp` action to our route. If you’re
not familiar with how events work in Ember, essentially the `onSignUp`
action, triggered in the template will hit the controller and then the
route. Since we didn’t define the action on the controller, the route
will handle it for us.

In the `onSignUp` action we’re getting the `email` and `password`, so
we'll use these to create a user record. We then save that record and
retrieve the session service. What is the session service? Well that
comes from `ember-simple-auth`, and it’s defined as:

> The session service provides access to the current session as well as
> methods to authenticate it, invalidate it, etc. It is the main
> interface for the application to Ember Simple Auth’s functionality.

With that in mind, we then call [authenticate][5]. Passing the function
call the authenticator we’d like to use, in our case
`authenticator:oauth2`, and the email/password as separate arguments.

Note that if you haven’t used async/await for your actions, that’s
alright. You can easily remove async/await from above and use
then/catch/finally to resolve your promises. If you’re interested in
setting this up for your project, check out Robert Jackson’s article
[An async/await Configuration Adventure][6].

There is one last thing we need to do, and that’s define the `user`
model. If we don’t do that, we’ll get a gnarly error like:

```javascript
TypeError: this.store.modelFactoryFor(...) is undefined
```

And that just makes us `[]` — so let’s do that next.

**Defining our User model**

Our user model is going to be simple, it’s just going to contain an
email and password. So let’s get to it.

Run the following generator:

```bash
ember g model user email:string password:string
```

The output of that command should be something like:

```bash
installing model
  create app/models/user.js
installing model-test
  create tests/unit/models/user-test.js
```

And the generated user model file should be:

```javascript
// frontend/models/user.js
import DS from 'ember-data';
import attr from 'ember-data/attr';

export default DS.Model.extend({
  email: attr('string'),
  password: attr('string')
});
```

Ok cool, let’s test this out!

**Testing out our Implementation**

So what does this all look like? Let’s start up our app.

But before we do, we need to remove the welcome page. To do that, open
`package.json` and remove the following:

```javascript
"ember-welcome-page": "^3.0.0"
```

```bash
ember g route dashboard

rm -f -r tests/unit/adapters/
rm -f -r tests/unit/routes/
```

Create serializers:

```bash
mkdir app/serializers/
touch app/serializers/application.js
```

```javascript
// frontend/app/serializers/application.js
import JSONAPISerializer from 'ember-data/serializers/json-api';

export default JSONAPISerializer.extend();
```

and install package: `ember-maybe-import-regenerator`

Start the server for testing: `ember s`

You should then be able to visit `http://localhost:4200/tests`,

Start the server: `ember server --proxy http://localhost:4000`

You should then be able to visit `http://localhost:4200/sign-up`,

You should experience this if everything worked well:

Yup, that’s right — we’re on our path to success!

**Where do we go from here?**

We’ll you may be thinking to yourself "Is this is it"? And the answer is
yes.

We did a bunch of setup work to get authentication going on the front-
end. What we now need to do is actually hook this up to an API.
Alternatively, we could mock out our endpoints in [ember-cli-mirage].
But we’re going to do something a bit different.

In my next article, I’m going to continue from this point and build out
authentication in Elixir/Phoenix and Guardian with you. In the mean
time, feel free to ping me on twitter or leave comments below. We’re
going to build out a rad authentication feature with Ember and
Elixir/Phoenix with Guardian. Stay tuned!

Oh yeah — and if you want to see this app put together, check it out
here: [https://github.com/alvincrespo/auth-example-frontend][7]

[1]: https://github.com/simplabs/ember-simple-auth
[2]: http://ember-simple-auth.com/api/classes/OAuth2PasswordGrantAuthenticator.html
[3]: http://ember-simple-auth.com/api/classes/OAuth2PasswordGrantAuthenticator.html#property_serverTokenEndpoint
[4]: http://ember-simple-auth.com/api/classes/OAuth2BearerAuthorizer.html
[5]: http://ember-simple-auth.com/api/classes/SessionService.html#method_authenticate
[6]: http://rwjblue.com/2017/10/30/async-await-configuration-adventure/
[7]: https://github.com/alvincrespo/auth-example-frontend
[8]: https://github.com/alvincrespo/auth-example-backend
[9]: https://blog.echobind.com/setting-up-ember-simple-auth-for-registration-26d2e22b9f72
[10]: https://blog.echobind.com/setting-up-phoenix-1-3-as-an-api-only-app-69ca8aa177ee
