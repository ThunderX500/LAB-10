import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

// Load the runtime API configuration before starting Angular.
fetch('/assets/env.json')
  .then(response => {
    if (!response.ok) throw new Error('Could not load API configuration');
    return response.json();
  })
  .then(env => {
    (window as any).env = env;
    return bootstrapApplication(App, appConfig);
  })
  .catch(err => console.error(err));
