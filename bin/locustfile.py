from locust import HttpLocust, TaskSet, task

class SdvdevTaskSet(TaskSet):
    @task(2)
    def index(self):
        self.client.get('/')

    @task(1)
    def blog(self):
        self.client.get('/blog/')

    @task(1)
    def meta_category(self):
        self.client.get('/travel/')

class SdvdevLocust(HttpLocust):
    task_set = SdvdevTaskSet

    # Minimum waiting time between the execution of locust tasks
    min_wait = 1000

    # Maximum waiting time between the execution of locust tasks
    max_wait = 1000
